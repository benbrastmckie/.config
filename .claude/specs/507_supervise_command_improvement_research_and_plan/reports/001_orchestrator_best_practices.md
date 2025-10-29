# Orchestrator Command Best Practices in Claude Code

## Metadata
- **Date**: 2025-10-28
- **Agent**: research-specialist
- **Topic**: Orchestrator Command Best Practices (commands that coordinate multiple subagents)
- **Report Type**: Best practices analysis
- **Reference Command**: /coordinate (.claude/commands/coordinate.md)
- **Complexity Level**: 3

## Executive Summary

Orchestrator commands in the Claude Code system coordinate multi-agent workflows through structured phases, delegating specialized work to subagents via the Task tool while maintaining path control and artifact organization. Analysis of `/coordinate` (2,500-3,000 lines), `/supervise` (2,300 lines), and `/orchestrate` (5,400+ lines) reveals critical architectural patterns that achieve 100% file creation reliability, >90% agent delegation rates, and <30% context usage throughout workflows. Key patterns include Phase 0 path pre-calculation, behavioral injection (not SlashCommand invocation), mandatory verification checkpoints with fail-fast error handling, imperative agent invocation without code block wrappers, and wave-based parallel execution for 40-60% time savings.

## Findings

### 1. Core Architectural Pattern: Pure Orchestration

**Pattern Definition** (from Command Architecture Standards, lines 42-109):

Orchestrator commands MUST follow the pure orchestration pattern:
- Phase 0: Pre-calculate ALL artifact paths before any agent invocations
- Phases 1-N: Invoke agents with pre-calculated paths → Verify → Extract metadata
- Completion: Report success + artifact locations

**Critical Prohibition**: Orchestrators MUST NEVER invoke other commands via SlashCommand tool.

**Implementation** (/coordinate, lines 32-132):

```markdown
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
```

**Why This Matters**:

Command chaining (via SlashCommand) causes:
1. Context bloat: Entire command prompts injected (~2000 lines each)
2. Broken behavioral injection: Cannot customize agent behavior
3. Lost path control: Cannot pre-calculate topic-based paths
4. No metadata extraction: Receive full content instead of structured summaries

**Evidence of Effectiveness**:
- /coordinate: >90% delegation rate (spec 495 validation)
- /supervise: >90% delegation rate (spec 438 validation)
- /orchestrate: Validated via unified test suite
- All achieve <30% context usage target

### 2. Phase 0: Path Pre-Calculation (Foundation Phase)

**Requirement** (/coordinate, lines 621-780):

Phase 0 MUST execute before any agent invocations to establish artifact organization foundation. This phase:
1. Sources unified location detection library
2. Analyzes workflow description to identify affected components
3. Determines next topic number in specs/ directory
4. Creates topic directory structure: `specs/NNN_topic/{reports,plans,summaries,debug,scripts,outputs}/`
5. Stores location context for injection into all subsequent phases
6. Verifies directory structure created successfully

**Implementation Pattern** (/coordinate, lines 746-778):

```bash
# Source unified location detection library
source "${CLAUDE_CONFIG:-${HOME}/.config}/.claude/lib/unified-location-detection.sh"

# Call unified initialization function
# This consolidates path pre-calculation + directory creation
if ! initialize_workflow_paths "$WORKFLOW_DESCRIPTION" "$WORKFLOW_SCOPE"; then
  echo "ERROR: Workflow initialization failed"
  exit 1
fi

# Reconstruct REPORT_PATHS array from exported variables
# (Bash arrays cannot be directly exported, so we use a helper function)
reconstruct_report_paths_array

# Emit progress marker
emit_progress "0" "Location pre-calculation complete (topic: $TOPIC_PATH)"
```

**Optimization Impact**:
- Previously used location-specialist agent (75.6k tokens, 25.2s)
- Now uses unified library (<11k tokens, <1s)
- **85% token reduction, 20x speedup** (Library API Reference, unified-location-detection.sh)

**Critical Success Factor**:
ALL paths MUST be calculated BEFORE Phase 1 begins. This enables:
- Context injection into agent prompts (agents receive pre-calculated paths)
- Verification checkpoints (commands know exact expected locations)
- Metadata extraction (commands parse structured JSON with paths)

### 3. Behavioral Injection Pattern (Not SlashCommand Invocation)

**Pattern Definition** (behavioral-injection.md, lines 8-39):

Commands inject context into agents via Task tool with behavioral file references instead of SlashCommand tool invocations. This pattern:
- Separates orchestrator role (calculates paths, manages state, delegates) from executor role (receives context, produces artifacts)
- Prevents context bloat (90% reduction per invocation: 150 lines → 15 lines)
- Enables hierarchical multi-agent coordination
- Achieves 100% file creation rate through explicit path injection

**Correct Invocation Pattern** (/coordinate, lines 841-863):

```markdown
**EXECUTE NOW**: USE the Task tool for each research topic (1 to $RESEARCH_COMPLEXITY) with these parameters:

- subagent_type: "general-purpose"
- description: "Research [insert topic name] with mandatory artifact creation"
- timeout: 300000  # 5 minutes per research agent
- prompt: |
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: [insert display-friendly topic name]
    - Report Path: [insert absolute path from REPORT_PATHS array]
    - Project Standards: /home/benjamin/.config/CLAUDE.md
    - Complexity Level: $RESEARCH_COMPLEXITY

    **CRITICAL**: Create report file at EXACT path provided above.

    Execute research following all guidelines in behavioral file.
    Return: REPORT_CREATED: [EXACT_ABSOLUTE_PATH]
```

**Key Elements**:
1. **Imperative instruction**: `**EXECUTE NOW**: USE the Task tool`
2. **Behavioral file reference**: `.claude/agents/research-specialist.md`
3. **No code block wrapper**: Task invocation is not fenced with ` ``` `
4. **Context injection only**: No duplication of agent STEP sequences
5. **Completion signal**: Agent must return `REPORT_CREATED:` for verification

**Anti-Pattern** (behavioral-injection.md, lines 262-294):

```markdown
❌ INCORRECT - Duplicating agent behavioral guidelines inline:

Task {
  prompt: "
    **STEP 1 (REQUIRED BEFORE STEP 2)**: Use Write tool to create file
    [... 30 lines of detailed instructions ...]

    **STEP 2 (REQUIRED BEFORE STEP 3)**: Conduct research
    [... 40 lines of detailed instructions ...]
  "
}
```

**Why This Fails**:
- Duplicates 646 lines of behavioral guidelines
- Creates maintenance burden (must sync with agent file)
- Adds 800+ lines of bloat across command file
- Violates single source of truth principle

**Structural Templates vs Behavioral Content** (behavioral-injection.md, lines 186-256):

IMPORTANT: Behavioral injection applies to agent guidelines, NOT structural templates.

**Structural Templates (MUST remain inline)**:
- Task invocation syntax: `Task { subagent_type, description, prompt }`
- Bash execution blocks: `**EXECUTE NOW**: bash commands`
- JSON schemas: Data structure definitions
- Verification checkpoints: `**MANDATORY VERIFICATION**: file checks`
- Critical warnings: `**CRITICAL**: error conditions`

**Behavioral Content (MUST be referenced)**:
- Agent STEP sequences: `STEP 1/2/3` procedural instructions
- File creation workflows: `PRIMARY OBLIGATION` blocks
- Agent verification steps: Agent-internal quality checks
- Output format specifications: Templates for agent responses

### 4. Imperative Agent Invocation Pattern (Standard 11)

**Requirement** (Command Architecture Standards, lines 1128-1307):

All Task invocations MUST use imperative instructions that signal immediate execution.

**Required Elements**:
1. **Imperative Instruction**: `**EXECUTE NOW**: USE the Task tool to invoke...`
2. **Agent Behavioral File Reference**: `Read and follow: .claude/agents/[agent-name].md`
3. **No Code Block Wrappers**: Task invocations must NOT be fenced with ` ```yaml `
4. **No "Example" Prefixes**: Remove documentation context
5. **Completion Signal Requirement**: `Return: REPORT_CREATED: ${REPORT_PATH}`

**Problem Context** (Standard 11, lines 1132-1148):

Documentation-only YAML blocks create 0% agent delegation rate because they appear as code examples rather than executable instructions. When Task invocations are wrapped in markdown code blocks (` ```yaml`) without preceding imperative instructions, Claude interprets them as syntax examples rather than actions to execute.

**Historical Evidence**:

**Spec 438** (2025-10-24): /supervise agent delegation fix
- Problem: 7 YAML blocks wrapped in markdown code fences
- Result: 0% delegation rate → >90% after removing fences
- Duration: Fixed in single phase (2 hours)

**Spec 495** (2025-10-27): /coordinate and /research delegation failures
- Problem: 9 invocations in /coordinate, 3 in /research using documentation-only pattern
- Evidence: Zero files in correct locations, all output to TODO1.md files
- Result: 0% → >90% delegation rate, 100% file creation reliability
- Duration: 2.5 hours for /coordinate, 1.5 hours for /research

**Anti-Pattern: Undermined Imperative** (behavioral-injection.md, lines 526-615):

```markdown
❌ INCORRECT - Undermining disclaimer:

**EXECUTE NOW**: USE the Task tool to invoke the research-specialist agent.

Task {
  prompt: "..."
}

**Note**: The actual implementation will generate N Task calls based on complexity.
```

**Why This Fails**:
The disclaimer contradicts the imperative directive, causing Claude to interpret the Task block as a template example rather than executable instruction. This results in 0% agent delegation rate.

**Correct Pattern**:

```markdown
✅ GOOD - No undermining disclaimers:

**EXECUTE NOW**: USE the Task tool for each research topic (1 to $RESEARCH_COMPLEXITY) with these parameters:

- subagent_type: "general-purpose"
- description: "Research [insert topic name] with mandatory artifact creation"
- prompt: |
    [context injection only]
```

Use "for each [item]" phrasing and `[insert value]` placeholders to indicate loops and substitution without undermining the imperative.

### 5. Mandatory Verification Checkpoints with Fail-Fast Error Handling

**Pattern** (/coordinate, lines 868-985):

After each agent invocation, commands MUST verify artifacts created at expected locations before proceeding.

**Implementation Example** (/coordinate, lines 873-985):

```bash
echo "════════════════════════════════════════════════════════"
echo "  MANDATORY VERIFICATION - Research Reports"
echo "════════════════════════════════════════════════════════"

VERIFICATION_FAILURES=0
SUCCESSFUL_REPORT_PATHS=()
FAILED_AGENTS=()

for i in $(seq 1 $RESEARCH_COMPLEXITY); do
  REPORT_PATH="${REPORT_PATHS[$i-1]}"

  # Emit progress marker
  emit_progress "1" "Verifying research report $i/$RESEARCH_COMPLEXITY"

  echo "Verifying Report $i: $(basename $REPORT_PATH)"

  # Check if file exists and has content (fail-fast, no retries)
  if [ -f "$REPORT_PATH" ] && [ -s "$REPORT_PATH" ]; then
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
    # Failure path - provide clear diagnostics
    echo "  ❌ ERROR: Report file verification failed"
    echo "     Expected: File exists and has content"
    if [ ! -f "$REPORT_PATH" ]; then
      echo "     Found: File does not exist"
    elif [ ! -s "$REPORT_PATH" ]; then
      echo "     Found: File exists but is empty"
    fi
    echo ""
    echo "  DIAGNOSTIC INFORMATION:"
    echo "    - Expected path: $REPORT_PATH"
    echo "    - Directory: $(dirname "$REPORT_PATH")"
    echo "    - Agent: research-specialist (agent $i)"
    echo ""
    echo "  Possible Causes:"
    echo "    - Agent did not complete successfully"
    echo "    - Agent wrote to wrong path"
    echo "    - Permission error preventing file creation"
    echo "    - Agent crashed or timed out"
    echo ""

    FAILED_AGENTS+=("agent_$i")
    VERIFICATION_FAILURES=$((VERIFICATION_FAILURES + 1))
  fi
done
```

**Error Message Structure** (/coordinate, lines 288-323):

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

**Fail-Fast Philosophy** (/coordinate, lines 269-287):

Key behaviors:
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

**Spec 057 Context** (behavioral-injection.md, lines 839-1030):

**Problem**: Bootstrap fallback mechanisms hiding configuration errors

**Example Fallback Removed**:
```bash
# Before (Silent fallback):
if ! source .claude/lib/workflow-detection.sh; then
  # Fallback function
  detect_workflow_scope() { echo "research-only"; }
fi

# After (Explicit error):
if ! source .claude/lib/workflow-detection.sh; then
  echo "ERROR: Failed to source workflow-detection.sh"
  echo "EXPECTED PATH: $SCRIPT_DIR/.claude/lib/workflow-detection.sh"
  echo "DIAGNOSTIC: ls -la $SCRIPT_DIR/.claude/lib/workflow-detection.sh"
  exit 1
fi
```

**Key Changes**:
- Removed 32 lines of fallback functions
- Enhanced 7 library sourcing error messages with diagnostics
- Exit immediately on configuration errors (no silent degradation)

**Critical Distinction**:

**Bootstrap Fallbacks** (REMOVED - Hide Configuration Errors):
- Silent function definitions when libraries missing
- Automatic directory creation masking agent delegation failures
- Fallback workflow detection when required libraries unavailable

**File Creation Verification Fallbacks** (PRESERVED - Detect Tool Failures):
- MANDATORY VERIFICATION after each agent file creation operation
- File existence checks, size validation
- Fallback file creation when agent succeeded but Write tool failed
- Performance: 70% → 100% file creation reliability (+43%)

### 6. Wave-Based Parallel Execution Pattern

**Overview** (/coordinate, lines 187-244):

Wave-based execution enables parallel implementation of independent phases, achieving 40-60% time savings compared to sequential execution.

**How It Works**:

1. **Dependency Analysis**: Parse implementation plan to identify phase dependencies
   - Uses `dependency-analyzer.sh` library
   - Extracts `dependencies: [N, M]` from each phase
   - Builds directed acyclic graph (DAG)

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

**Example** (/coordinate, lines 212-234):

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
  Wave 1: [Phase 1, Phase 2]          ← 2 phases in parallel
  Wave 2: [Phase 3, Phase 4, Phase 5] ← 3 phases in parallel
  Wave 3: [Phase 6, Phase 7]          ← 2 phases in parallel
  Wave 4: [Phase 8]                   ← 1 phase

Time Savings:
  Sequential: 8 phases × avg_time = 8T
  Wave-based: 4 waves × avg_time = 4T
  Savings: 50%
```

**Performance Impact**:
- Best case: 60% time savings (many independent phases)
- Typical case: 40-50% time savings (moderate dependencies)
- Worst case: 0% savings (fully sequential dependencies)
- No overhead for plans with <3 phases (single wave)

**Implementation** (/coordinate, lines 1306-1515):

```bash
# Analyze plan dependencies and calculate waves
DEPENDENCY_ANALYSIS=$(analyze_dependencies "$PLAN_PATH")

# Extract waves information
WAVES=$(echo "$DEPENDENCY_ANALYSIS" | jq '.waves')
WAVE_COUNT=$(echo "$WAVES" | jq 'length')
TOTAL_PHASES=$(echo "$DEPENDENCY_ANALYSIS" | jq '.dependency_graph.nodes | length')

# Display wave structure
for ((wave_num=1; wave_num<=WAVE_COUNT; wave_num++)); do
  WAVE=$(echo "$WAVES" | jq ".[$((wave_num-1))]")
  WAVE_PHASES=$(echo "$WAVE" | jq -r '.phases[]')
  PHASE_COUNT=$(echo "$WAVE" | jq '.phases | length')
  CAN_PARALLEL=$(echo "$WAVE" | jq -r '.can_parallel')

  echo "  Wave $wave_num: $PHASE_COUNT phase(s) $([ "$CAN_PARALLEL" == "true" ] && echo "[PARALLEL]" || echo "[SEQUENTIAL]")"
done

# Invoke implementer-coordinator agent for wave execution
Task {
  subagent_type: "general-purpose"
  description: "Orchestrate wave-based implementation with parallel execution"
  prompt: |
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/implementer-coordinator.md

    **Wave Execution Context**:
    - Total Waves: $WAVE_COUNT
    - Wave Structure: $WAVES
    - Dependency Graph: [dependency analysis]

    Execute phases wave-by-wave, parallel within waves when possible.
    Return: IMPLEMENTATION_STATUS: {complete|partial|failed}
}
```

### 7. Context Management and Metadata Extraction

**Target** (/coordinate, lines 246-268):

- **Context Usage**: <30% throughout workflow (target achieved via context pruning)
  - Phase 1 (Research): 80-90% reduction via metadata extraction
  - Phase 2 (Planning): 80-90% reduction + pruning research if plan-only workflow
  - Phase 3 (Implementation): Aggressive pruning of wave metadata
  - Phase 4 (Testing): Metadata only (pass/fail status)
  - Phase 5 (Debug): Prune test output after completion
  - Phase 6 (Documentation): Final pruning, <30% context usage overall

**Metadata Extraction Pattern** (/coordinate, lines 1225-1267):

```bash
# Extract plan metadata for reporting
PLAN_COMPLEXITY=$(grep "Complexity:" "$PLAN_PATH" | head -1 | cut -d: -f2 | xargs || echo "unknown")
PLAN_EST_TIME=$(grep "Estimated Total Time:" "$PLAN_PATH" | cut -d: -f2 | xargs || echo "unknown")

echo "Plan Metadata:"
echo "  Phases: $PHASE_COUNT"
echo "  Complexity: $PLAN_COMPLEXITY"
echo "  Est. Time: $PLAN_EST_TIME"

# Save checkpoint after Phase 2
ARTIFACT_PATHS_JSON=$(cat <<EOF
{
  "research_reports": [$(printf '"%s",' "${SUCCESSFUL_REPORT_PATHS[@]}" | sed 's/,$//')]
  "plan_path": "$PLAN_PATH"
}
EOF
)
save_checkpoint "coordinate" "phase_2" "$ARTIFACT_PATHS_JSON"

# Context pruning after Phase 2
store_phase_metadata "phase_2" "complete" "$PLAN_PATH"
apply_pruning_policy "planning" "$WORKFLOW_SCOPE"
echo "Phase 2 metadata stored (context reduction: 80-90%)"
```

**Forward Message Pattern** (CLAUDE.md, hierarchical_agent_architecture section):

Pass subagent responses directly without re-summarization. Agents return metadata (path, status) not full summaries.

**Benefits**:
- 92-97% context reduction through metadata-only passing
- 60-80% time savings with parallel subagent execution
- Enables 10+ research topics (vs 4 without recursion)

### 8. Progress Streaming and Checkpoint Recovery

**Progress Markers** (/coordinate, lines 341-349):

Emit silent progress markers at phase boundaries:
```
PROGRESS: [Phase N] - [action]
```

Example: `PROGRESS: [Phase 1] - Research complete (4/4 succeeded)`

**Checkpoint Pattern** (/coordinate, lines 336-339):

Checkpoints saved after Phases 1-4. Auto-resumes from last completed phase on startup.

**Implementation** (/coordinate, lines 1043-1061):

```bash
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
PHASE_1_ARTIFACTS="${SUCCESSFUL_REPORT_PATHS[@]}"
store_phase_metadata "phase_1" "complete" "$PHASE_1_ARTIFACTS"
```

**Auto-Resume** (/coordinate, lines 637-679):

```bash
# Check for existing checkpoint (auto-resume capability)
RESUME_DATA=$(restore_checkpoint "coordinate" 2>/dev/null || echo "")
if [ -n "$RESUME_DATA" ]; then
  RESUME_PHASE=$(echo "$RESUME_DATA" | jq -r '.current_phase // empty')
else
  RESUME_PHASE=""
fi

if [ -n "$RESUME_PHASE" ]; then
  echo "════════════════════════════════════════════════════════"
  echo "  CHECKPOINT DETECTED - RESUMING WORKFLOW"
  echo "════════════════════════════════════════════════════════"
  emit_progress "Resume" "Skipping completed phases 0-$((RESUME_PHASE - 1))"
  echo "Resuming from Phase $RESUME_PHASE..."
fi
```

### 9. Library Integration and Shared Utilities

**Required Libraries** (/coordinate, lines 318-332):

- workflow-detection.sh - Workflow scope detection and phase execution control
- error-handling.sh - Error classification and diagnostic message generation
- checkpoint-utils.sh - Workflow resume capability and state management
- unified-logger.sh - Progress tracking and event logging
- unified-location-detection.sh - Topic directory structure creation
- metadata-extraction.sh - Context reduction via metadata-only passing
- context-pruning.sh - Context optimization between phases
- dependency-analyzer.sh - Wave-based execution and dependency graph analysis

**Library Sourcing Pattern** (/coordinate, lines 352-388):

```bash
# Determine script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load required libraries using consolidated function
echo "Loading required libraries..."

# Source library-sourcing utilities first
if [ -f "$SCRIPT_DIR/../lib/library-sourcing.sh" ]; then
  source "$SCRIPT_DIR/../lib/library-sourcing.sh"
else
  echo "ERROR: Required library not found: library-sourcing.sh"
  echo "Expected location: $SCRIPT_DIR/../lib/library-sourcing.sh"
  echo "Diagnostic commands:"
  echo "  ls -la $SCRIPT_DIR/../lib/ | grep library-sourcing"
  exit 1
fi

# Source all required libraries using consolidated function
if ! source_required_libraries "dependency-analyzer.sh"; then
  # Error already reported by source_required_libraries()
  exit 1
fi

echo "✓ All libraries loaded successfully"
```

**Function Verification** (/coordinate, lines 423-463):

```bash
# Verify critical functions are defined after library sourcing
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
  echo "Diagnostic commands:"
  echo "  ls -la $SCRIPT_DIR/../lib/"
  echo "  declare -F | grep -E '(function_name)'"
  exit 1
fi
```

**Available Utility Functions** (/coordinate, lines 471-516):

| Function | Library | Purpose |
|----------|---------|---------|
| `detect_workflow_scope()` | workflow-detection.sh | Determine workflow type from description |
| `should_run_phase()` | workflow-detection.sh | Check if phase executes for current scope |
| `classify_error()` | error-handling.sh | Classify error type (transient/permanent/fatal) |
| `suggest_recovery()` | error-handling.sh | Suggest recovery action based on error type |
| `emit_progress()` | unified-logger.sh | Emit silent progress marker |
| `save_checkpoint()` | checkpoint-utils.sh | Save workflow checkpoint for resume |
| `restore_checkpoint()` | checkpoint-utils.sh | Load most recent checkpoint |
| `analyze_dependencies()` | dependency-analyzer.sh | Calculate wave structure from plan |

### 10. Workflow Scope Detection

**Scope Types** (/coordinate, lines 135-159):

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

**Implementation** (/coordinate, lines 683-744):

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
```

**Phase Execution Check** (/coordinate, lines 791-800):

```bash
should_run_phase 1 || {
  echo "⏭️  Skipping Phase 1 (Research)"
  echo "  Reason: Workflow type is $WORKFLOW_SCOPE"
  echo ""
  display_brief_summary
  exit 0
}
```

## Recommendations

### 1. Imperative Agent Invocation is Non-Negotiable

**Recommendation**: All orchestrator commands MUST use imperative pattern for agent invocations.

**Required Pattern**:
```markdown
**EXECUTE NOW**: USE the Task tool for each [item] with these parameters:

- subagent_type: "general-purpose"
- description: "[task description]"
- prompt: |
    Read and follow ALL behavioral guidelines from:
    .claude/agents/[agent-name].md

    **Workflow-Specific Context**:
    - [Context key]: [insert value]
    - Output Path: [insert pre-calculated path]

    Execute per behavioral guidelines.
    Return: [SIGNAL]: [path]
```

**Critical Elements**:
- `**EXECUTE NOW**` imperative directive
- No code block wrappers (no ` ```yaml `)
- No undermining disclaimers after imperative
- Behavioral file reference (not inline duplication)
- Pre-calculated paths injected as context
- Completion signal requirement

**Evidence**: Spec 438 (7 YAML blocks), Spec 495 (9 in /coordinate, 3 in /research), Spec 502 (undermined imperative) all achieved 0% → >90% delegation rates after applying this pattern.

**Validation**: Run `.claude/lib/validate-agent-invocation-pattern.sh` to detect violations.

### 2. Phase 0 Path Pre-Calculation is Mandatory

**Recommendation**: ALL orchestrator commands MUST include Phase 0 for path pre-calculation BEFORE any agent invocations.

**Implementation**:
```bash
# Use unified workflow initialization
source .claude/lib/workflow-initialization.sh

if ! initialize_workflow_paths "$WORKFLOW_DESCRIPTION" "$WORKFLOW_SCOPE"; then
  echo "ERROR: Workflow initialization failed"
  exit 1
fi

# Results in:
# - TOPIC_PATH: specs/NNN_topic/
# - REPORT_PATHS: array of pre-calculated report paths
# - PLAN_PATH: pre-calculated plan path
# - All subdirectories created
```

**Why This Matters**:
- Enables context injection into agents (agents receive paths, don't calculate)
- Enables verification checkpoints (commands know expected locations)
- Achieves 85% token reduction + 20x speedup vs agent-based detection
- Guarantees topic-based organization (all artifacts in one directory)

**When Required**:
- ✅ All orchestrator commands (research → plan → implement workflows)
- ✅ Commands coordinating parallel agents
- ✅ Commands with file creation requirements

### 3. Mandatory Verification with Fail-Fast Error Handling

**Recommendation**: Implement verification checkpoints after EVERY agent file creation operation.

**Pattern**:
```bash
echo "════════════════════════════════════════════════════════"
echo "  MANDATORY VERIFICATION - [Artifact Type]"
echo "════════════════════════════════════════════════════════"

if [ -f "$EXPECTED_PATH" ] && [ -s "$EXPECTED_PATH" ]; then
  echo "✅ VERIFIED: [Artifact] created successfully"
  SUCCESSFUL_PATHS+=("$EXPECTED_PATH")
else
  echo "❌ ERROR: [Artifact] file verification failed"
  echo "   Expected: File exists at $EXPECTED_PATH"
  if [ ! -f "$EXPECTED_PATH" ]; then
    echo "   Found: File does not exist"
  fi
  echo ""
  echo "DIAGNOSTIC INFORMATION:"
  echo "  - Expected path: $EXPECTED_PATH"
  echo "  - Agent: [agent-name]"
  echo "  - Directory status:"
  ls -la "$(dirname "$EXPECTED_PATH")"
  echo ""
  echo "What to check next:"
  echo "  1. Check agent output for errors"
  echo "  2. Verify agent behavioral file"
  echo "  3. Check permissions"
  echo ""
  echo "Workflow TERMINATED."
  exit 1
fi
```

**Fail-Fast Principles**:
- NO retries (single execution attempt)
- NO fallbacks for bootstrap operations (expose configuration errors)
- Clear diagnostics (what failed, why, how to debug)
- Debugging guidance (specific commands to investigate)
- Exit immediately (no silent degradation)

**Exception**: Partial research failure - continue if ≥50% agents succeed (Phase 1 only)

**Evidence**: Spec 057 removed 32 lines of bootstrap fallbacks, enhanced 7 library error messages. Result: 100% bootstrap reliability through fail-fast.

### 4. Context Management Through Metadata Extraction

**Recommendation**: Use metadata-only passing between agents and phases.

**Pattern**:
```bash
# After agent completes, extract metadata only
PLAN_COMPLEXITY=$(grep "Complexity:" "$PLAN_PATH" | head -1 | cut -d: -f2 | xargs)
PLAN_PHASES=$(grep -c "^### Phase [0-9]" "$PLAN_PATH")

# Store metadata in checkpoint (not full content)
ARTIFACT_METADATA=$(cat <<EOF
{
  "plan_path": "$PLAN_PATH",
  "complexity": "$PLAN_COMPLEXITY",
  "phases": $PLAN_PHASES
}
EOF
)

# Apply context pruning
store_phase_metadata "phase_2" "complete" "$PLAN_PATH"
apply_pruning_policy "planning" "$WORKFLOW_SCOPE"
```

**Benefits**:
- 80-90% context reduction per phase
- <30% cumulative context usage target
- Enables 10+ research topics (vs 4 without metadata extraction)
- Enables parallel execution (metadata shared across threads)

**When to Apply**:
- After every agent invocation (store path + summary only)
- After every phase completion (prune full outputs)
- Before invoking next phase (minimal context for next agent)

### 5. Structural Templates vs Behavioral Content Separation

**Recommendation**: Keep structural templates inline, reference behavioral content from agent files.

**Structural Templates (INLINE)**:
- Task invocation syntax: `Task { subagent_type, description, prompt }`
- Bash execution blocks: `**EXECUTE NOW**: bash commands`
- JSON schemas: Data structure definitions
- Verification checkpoints: `**MANDATORY VERIFICATION**: checks`
- Critical warnings: `**CRITICAL**: constraints`

**Behavioral Content (REFERENCED)**:
- Agent STEP sequences: `STEP 1/2/3` procedures
- File creation workflows: `PRIMARY OBLIGATION` blocks
- Agent verification steps: Internal quality checks
- Output format specifications: Response templates

**Why This Matters**:
- 90% reduction in agent invocation code (150 lines → 15 lines)
- Single source of truth (agent files authoritative)
- No synchronization burden (updates apply automatically)
- Cleaner commands (focus on orchestration)

**Anti-Pattern**: Duplicating agent STEP sequences inline creates 800+ lines of bloat and maintenance burden.

### 6. Wave-Based Parallel Execution for Performance

**Recommendation**: Implement wave-based execution for plans with ≥3 phases and dependency information.

**Implementation**:
```bash
# Analyze dependencies and calculate waves
DEPENDENCY_ANALYSIS=$(analyze_dependencies "$PLAN_PATH")
WAVES=$(echo "$DEPENDENCY_ANALYSIS" | jq '.waves')
WAVE_COUNT=$(echo "$WAVES" | jq 'length')

# Execute wave-by-wave
for ((wave_num=1; wave_num<=WAVE_COUNT; wave_num++)); do
  WAVE_PHASES=$(echo "$WAVES" | jq -r ".[$((wave_num-1))].phases[]")

  # Invoke implementer-coordinator for wave
  Task {
    prompt: "
      Execute Wave $wave_num with phases: $WAVE_PHASES
      All phases in this wave can execute in parallel.
    "
  }

  # Wait for wave completion before next wave
  verify_wave_completion "$wave_num"
done
```

**Performance Impact**:
- Best case: 60% time savings (many independent phases)
- Typical case: 40-50% time savings (moderate dependencies)
- No overhead for simple plans (<3 phases)

**When to Apply**:
- Plans with phase dependency information
- Implementation phases (not research/planning)
- Plans with ≥3 phases

**Library**: `.claude/lib/dependency-analyzer.sh` for wave calculation

### 7. Workflow Scope Detection for Conditional Execution

**Recommendation**: Detect workflow scope from description and skip inappropriate phases.

**Implementation**:
```bash
WORKFLOW_SCOPE=$(detect_workflow_scope "$WORKFLOW_DESCRIPTION")

# Check before each phase
should_run_phase 2 || {
  echo "⏭️  Skipping Phase 2 (Planning)"
  echo "  Reason: Workflow type is $WORKFLOW_SCOPE"
  display_brief_summary
  exit 0
}
```

**Benefits**:
- Appropriate phase execution (no unnecessary planning for research-only)
- Clear user feedback (explains why phases skipped)
- Performance optimization (skip phases, not execute-then-discard)

**Scope Types**: research-only, research-and-plan (most common), full-implementation, debug-only

### 8. Checkpoint Recovery for Resumable Workflows

**Recommendation**: Save checkpoints after each phase for auto-resume capability.

**Implementation**:
```bash
# Save checkpoint after phase completion
ARTIFACT_PATHS_JSON=$(cat <<EOF
{
  "current_phase": $PHASE_NUMBER,
  "research_reports": [paths],
  "plan_path": "$PLAN_PATH"
}
EOF
)
save_checkpoint "coordinate" "phase_$PHASE_NUMBER" "$ARTIFACT_PATHS_JSON"

# Auto-resume on startup
RESUME_DATA=$(restore_checkpoint "coordinate" 2>/dev/null || echo "")
if [ -n "$RESUME_DATA" ]; then
  RESUME_PHASE=$(echo "$RESUME_DATA" | jq -r '.current_phase')
  echo "Resuming from Phase $RESUME_PHASE..."
fi
```

**Benefits**:
- Workflow continuity (recover from interruptions)
- No duplicate work (skip completed phases)
- State preservation (artifact paths, status)

**When to Apply**: After Phases 1-4 (research, planning, implementation, testing)

### 9. Progress Streaming for Visibility

**Recommendation**: Emit silent PROGRESS: markers at phase boundaries and major operations.

**Format**:
```
PROGRESS: [Phase N] - [action_description]
```

**Examples**:
```
PROGRESS: [Phase 0] - Location pre-calculation complete
PROGRESS: [Phase 1] - Invoking 4 research agents in parallel
PROGRESS: [Phase 1] - All research agents completed
PROGRESS: [Phase 2] - Planning phase started
PROGRESS: [Phase 2] - Planning complete (plan created with 8 phases)
```

**When to Emit**:
- Phase transitions (start/complete)
- Agent invocations (before/after)
- Verification checkpoints (completion)
- Long operations (every 30s or at natural boundaries)

**Benefits**:
- User visibility (know what's happening)
- External monitoring (scripts can parse markers)
- Debugging aid (last marker before failure)

### 10. Library Integration for Code Reuse

**Recommendation**: Use shared utility libraries for common operations.

**Required Libraries**:
- workflow-detection.sh (scope detection, phase execution)
- error-handling.sh (error classification, diagnostics)
- checkpoint-utils.sh (save/restore checkpoints)
- unified-logger.sh (progress markers)
- unified-location-detection.sh (path calculation)
- metadata-extraction.sh (context reduction)
- context-pruning.sh (context optimization)
- dependency-analyzer.sh (wave calculation)

**Sourcing Pattern**:
```bash
# Source library-sourcing utilities first
source "$SCRIPT_DIR/../lib/library-sourcing.sh"

# Source all required libraries using consolidated function
if ! source_required_libraries "dependency-analyzer.sh"; then
  exit 1  # Error already reported
fi

# Verify critical functions available
verify_required_functions "detect_workflow_scope" "save_checkpoint" "emit_progress"
```

**Benefits**:
- Code reuse (single implementation)
- Consistency (same behavior across commands)
- Testing (test libraries once, benefits all commands)
- Maintenance (update once, applies everywhere)

## Implementation Guidance

### Creating a New Orchestrator Command

**Step-by-Step Process**:

1. **Define Command Metadata** (YAML frontmatter):
```yaml
---
allowed-tools: Task, TodoWrite, Bash, Read
argument-hint: <workflow-description>
description: Coordinate [workflow type] with [agent pattern]
command-type: primary
dependent-commands: [list of agents used]
---
```

2. **Add Role Clarification** (Required header):
```markdown
## YOUR ROLE: WORKFLOW ORCHESTRATOR

**YOU ARE THE ORCHESTRATOR** for this multi-agent workflow.

**YOUR RESPONSIBILITIES**:
1. Pre-calculate ALL artifact paths before any agent invocations
2. Determine workflow scope
3. Invoke specialized agents via Task tool
4. Verify agent outputs at mandatory checkpoints
5. Extract and aggregate metadata from results

**YOU MUST NEVER**:
1. Execute tasks yourself using Read/Grep/Write/Edit tools
2. Invoke other commands via SlashCommand tool
3. Modify or create files directly (except in Phase 0 setup)
4. Skip mandatory verification checkpoints
```

3. **Implement Phase 0 - Path Pre-Calculation**:
```bash
# Source unified workflow initialization
source .claude/lib/workflow-initialization.sh

# Initialize workflow paths
if ! initialize_workflow_paths "$WORKFLOW_DESCRIPTION" "$WORKFLOW_SCOPE"; then
  echo "ERROR: Workflow initialization failed"
  exit 1
fi

# Verify directory structure created
verify_topic_directory_structure "$TOPIC_PATH"
```

4. **Implement Phase 1-N with Imperative Agent Invocations**:
```markdown
**EXECUTE NOW**: USE the Task tool for each [item] with these parameters:

- subagent_type: "general-purpose"
- description: "[task with mandatory file creation]"
- prompt: |
    Read and follow ALL behavioral guidelines from:
    .claude/agents/[agent-name].md

    **Workflow-Specific Context**:
    - [Key]: [Value from Phase 0]
    - Output Path: [Pre-calculated path]

    Execute per behavioral guidelines.
    Return: [SIGNAL]: [path]
```

5. **Add Mandatory Verification After Each Agent**:
```bash
echo "════════════════════════════════════════════════════════"
echo "  MANDATORY VERIFICATION - [Artifact Type]"
echo "════════════════════════════════════════════════════════"

if [ -f "$EXPECTED_PATH" ] && [ -s "$EXPECTED_PATH" ]; then
  echo "✅ VERIFIED: [Artifact] created successfully"
else
  echo "❌ ERROR: [Artifact] verification failed"
  echo "DIAGNOSTIC INFORMATION:"
  [error details + debugging commands]
  exit 1
fi
```

6. **Add Checkpoint Saves After Each Phase**:
```bash
save_checkpoint "command_name" "phase_$N" "$ARTIFACT_METADATA_JSON"
```

7. **Add Progress Markers**:
```bash
emit_progress "$PHASE_NUMBER" "[action description]"
```

8. **Test Command**:
```bash
# Run validation script
.claude/lib/validate-agent-invocation-pattern.sh .claude/commands/new_command.md

# Run orchestration test suite
.claude/tests/test_orchestration_commands.sh
```

### Converting Existing Commands to Orchestrator Pattern

**Migration Checklist**:

- [ ] Add role clarification header
- [ ] Add Phase 0 path pre-calculation
- [ ] Convert SlashCommand invocations to Task + behavioral injection
- [ ] Remove code block wrappers from Task invocations (` ```yaml `)
- [ ] Add imperative directives (`**EXECUTE NOW**`)
- [ ] Add mandatory verification checkpoints
- [ ] Add fail-fast error handling with diagnostics
- [ ] Source required libraries
- [ ] Add checkpoint saves
- [ ] Add progress markers
- [ ] Separate structural templates from behavioral content
- [ ] Test delegation rate (target: >90%)
- [ ] Test file creation reliability (target: 100%)
- [ ] Test context usage (target: <30%)

**Validation**:
```bash
# Delegation rate test
grep -c "REPORT_CREATED:" [command_output] / [expected_agent_count]
# Target: >90%

# File creation test
find .claude/specs/NNN_topic/ -type f | wc -l
# Target: All expected files present

# Context usage (approximate via file size)
wc -l .claude/commands/[command].md
# Target: 2,000-3,000 lines for orchestrator commands
```

## References

### Primary Sources
- /home/benjamin/.config/.claude/commands/coordinate.md (2,500-3,000 lines)
- /home/benjamin/.config/.claude/commands/supervise.md (2,300 lines)
- /home/benjamin/.config/.claude/commands/orchestrate.md (5,400+ lines)
- /home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md (2,000+ lines)
- /home/benjamin/.config/.claude/docs/concepts/patterns/behavioral-injection.md (1,160 lines)

### Specifications Referenced
- Spec 438 (2025-10-24): /supervise agent delegation fix (7 YAML blocks)
- Spec 495 (2025-10-27): /coordinate and /research delegation failures (12 invocations)
- Spec 502 (2025-10-27): Undermined imperative pattern discovery
- Spec 057 (2025-10-27): /supervise robustness improvements (32 lines fallbacks removed)
- Spec 497 (2025-10-27): Unified orchestration command improvements

### Library References
- .claude/lib/workflow-initialization.sh - Unified path calculation
- .claude/lib/workflow-detection.sh - Scope detection
- .claude/lib/error-handling.sh - Error classification and diagnostics
- .claude/lib/checkpoint-utils.sh - State management
- .claude/lib/unified-logger.sh - Progress tracking
- .claude/lib/metadata-extraction.sh - Context reduction
- .claude/lib/dependency-analyzer.sh - Wave calculation

### Test Infrastructure
- .claude/lib/validate-agent-invocation-pattern.sh - Anti-pattern detection
- .claude/tests/test_orchestration_commands.sh - Comprehensive test suite
- .claude/docs/guides/orchestration-troubleshooting.md - Debugging guide

### Validation Scripts
- validate-agent-invocation-pattern.sh: Detects documentation-only YAML blocks
- test_orchestration_commands.sh: Delegation rate + file creation reliability tests

## Metadata
- **Total Files Analyzed**: 5 primary command files, 2 documentation files, 8 library files
- **Lines of Code Analyzed**: ~12,000 lines across command files
- **Specifications Referenced**: 5 specs (438, 495, 497, 502, 057)
- **Performance Metrics**: >90% delegation rate, 100% file creation reliability, <30% context usage
- **Time Savings**: 40-60% via wave-based execution, 85% token reduction via unified library
