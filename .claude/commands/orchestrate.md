---
allowed-tools: Task, TodoWrite, Read, Write, Bash, Grep, Glob
argument-hint: <workflow-description> [--parallel] [--sequential] [--create-pr] [--dry-run]
description: Coordinate subagents through end-to-end development workflows
command-type: primary
dependent-commands: research, plan, implement, debug, test, document, github-specialist
---

<!-- ═══════════════════════════════════════════════════════════════ -->
<!-- CRITICAL ARCHITECTURAL PATTERN - DO NOT VIOLATE                 -->
<!-- ═══════════════════════════════════════════════════════════════ -->
<!-- /orchestrate MUST NEVER invoke other slash commands             -->
<!-- FORBIDDEN TOOLS: SlashCommand                                   -->
<!-- REQUIRED PATTERN: Task tool → Specialized agents                -->
<!-- ═══════════════════════════════════════════════════════════════ -->
<!--                                                                 -->
<!-- WHY THIS MATTERS:                                               -->
<!-- 1. Context Bloat: SlashCommand expands entire command prompts  -->
<!--    (3000+ tokens each), consuming valuable context window      -->
<!-- 2. Broken Behavioral Injection: Commands invoked via            -->
<!--    SlashCommand cannot receive artifact path context from       -->
<!--    location-specialist, breaking topic-based organization       -->
<!-- 3. Lost Control: Orchestrator cannot customize agent behavior,  -->
<!--    inject topic numbers, or ensure artifacts in correct paths   -->
<!-- 4. Anti-Pattern Propagation: Sets bad example for future        -->
<!--    command development                                          -->
<!--                                                                 -->
<!-- CORRECT PATTERN:                                                -->
<!--   /orchestrate → Task(plan-architect) with artifact context     -->
<!--   NOT: /orchestrate → SlashCommand("/plan")                     -->
<!--                                                                 -->
<!-- ENFORCEMENT:                                                    -->
<!-- - Validation script: .claude/lib/validate-orchestrate-pattern.sh-->
<!-- - Runs in test suite: Fails if SlashCommand detected           -->
<!-- - Code review: Reject PRs violating this pattern               -->
<!-- ═══════════════════════════════════════════════════════════════ -->

# Multi-Agent Workflow Orchestration

**YOU MUST orchestrate a 6-phase development workflow by delegating to specialized subagents.**

**YOUR ROLE**: You are the WORKFLOW ORCHESTRATOR, not the executor.
- **DO NOT** execute research/planning/implementation/testing/debugging/documentation yourself using Read/Write/Grep/Bash tools
- **ONLY** use Task tool to invoke specialized agents for each phase
- **YOUR RESPONSIBILITY**: Coordinate agents, verify outputs, aggregate results, manage checkpoints

**EXECUTION MODEL**: Pure orchestration across all 6 phases
- **Phase 0 (Location)**: Use unified location detection library to create topic directory structure
- **Phase 1 (Research)**: Invoke 2-4 research-specialist agents in parallel
- **Phase 2 (Planning)**: Invoke plan-architect agent with research report paths
- **Phase 3 (Implementation)**: Invoke code-writer agent with plan path (wave-based execution)
- **Phase 4 (Testing)**: Invoke test-specialist to execute comprehensive test suite
- **Phase 5 (Debugging)**: Conditionally invoke debug-specialist if Phase 4 tests fail
- **Phase 6 (Documentation)**: Invoke doc-writer agent with implementation summary and test results

**CRITICAL INSTRUCTIONS**:
- Execute all workflow phases in EXACT sequential order (Phases 0-6)
- DO NOT skip agent invocations in favor of direct execution
- DO NOT skip verification of agent outputs
- DO NOT skip checkpoint saves between phases
- **FILE CREATION ENFORCEMENT**: Verify files created BEFORE proceeding to next phase
- Fallback mechanisms ensure 100% workflow completion
- Use metadata-based context passing (forward_message pattern) for <30% context usage

**FILE CREATION VERIFICATION REQUIREMENT**:
Each phase MUST verify that agents created required files BEFORE marking phase complete:
- Phase 0: Verify topic directory structure created
- Phase 1: Verify all research report files exist
- Phase 2: Verify implementation plan file exists
- Phase 3: Verify code files and implementation complete
- Phase 4: Verify test output file exists (test_results.txt)
- Phase 5: Verify debug reports exist (if invoked due to test failures)
- Phase 6: Verify documentation and workflow summary files exist

## Reference Files

This command uses standardized patterns defined in external reference files:

- **Agent Templates**: `.claude/docs/reference/orchestration-patterns.md`
  - Complete agent prompt templates for all 5 agents
  - Phase coordination patterns (parallel, sequential, adaptive, conditional)
  - Checkpoint structure and operations
  - Error recovery patterns

- **Command Examples**: `.claude/docs/command-examples.md`
  - Dry-run mode output examples
  - Dashboard progress formatting
  - Checkpoint save/restore patterns
  - Test execution patterns
  - Git commit formatting

- **Logging Patterns**: `.claude/docs/logging-patterns.md`
  - PROGRESS: marker format and usage
  - Structured logging format
  - Error logging with recovery suggestions
  - Summary report format
  - File path output format

## Dry-Run Mode (Preview and Validation)

Preview the complete workflow execution without invoking agents or making changes using the `--dry-run` flag:

```bash
/orchestrate "Add user authentication with JWT tokens" --dry-run
```

**Dry-Run Analysis**:
1. **Workflow parsing**: Analyze workflow description and determine workflow type
2. **Research topic identification**: Identify research topics from workflow description
3. **Agent planning**: Determine which agents will be invoked for each phase
4. **Duration estimation**: Estimate time based on workflow complexity and agent metrics
5. **Execution preview**: Display phase-by-phase workflow with agent assignments
6. **Artifact preview**: List reports, plans, and files that would be created
7. **Confirmation prompt**: Option to proceed with actual workflow execution

For detailed preview output examples, workflow type detection, use cases, and implementation details, see [Orchestration Alternatives](.claude/docs/reference/orchestration-alternatives.md).

## Workflow Analysis

YOU MUST first analyze the workflow description to identify the natural phases and requirements.

## Workflow Execution Infrastructure

Before beginning the workflow, YOU MUST initialize the execution infrastructure for progress tracking, state management, and checkpoint persistence.

### Workflow Initialization

**EXECUTE NOW**: Initialize TodoWrite and workflow state at the start of every orchestration.

**Step 1: Initialize TodoWrite with Workflow Phases**

USE the TodoWrite tool to create a task list tracking all workflow phases:

```json
{
  "todos": [
    {
      "content": "Analyze workflow and identify research topics",
      "status": "pending",
      "activeForm": "Analyzing workflow and identifying research topics"
    },
    {
      "content": "Execute parallel research phase",
      "status": "pending",
      "activeForm": "Executing parallel research phase"
    },
    {
      "content": "Create implementation plan",
      "status": "pending",
      "activeForm": "Creating implementation plan"
    },
    {
      "content": "Implement features with testing",
      "status": "pending",
      "activeForm": "Implementing features with testing"
    },
    {
      "content": "Debug and fix test failures (if needed)",
      "status": "pending",
      "activeForm": "Debugging and fixing test failures"
    },
    {
      "content": "Generate documentation and workflow summary",
      "status": "pending",
      "activeForm": "Generating documentation and workflow summary"
    }
  ]
}
```

**Step 2: Initialize Workflow State**

CREATE the workflow_state structure in memory (no tool invocation - this is internal state tracking):

```yaml
workflow_state:
  workflow_description: "[User's complete workflow description]"
  workflow_type: "feature|refactor|debug|investigation"  # Determined from analysis
  thinking_mode: null  # Will be set based on complexity score
  current_phase: "analysis"
  completed_phases: []
  project_name: ""  # Auto-generated slug from workflow description

  # Context preservation (file paths only, not content)
  context_preservation:
    research_reports: []  # Paths to created report files
    plan_path: ""         # Path to implementation plan
    implementation_status:
      tests_passing: false
      files_modified: []
    debug_reports: []     # Paths to debug report files
    documentation_paths: [] # Paths to generated documentation

  # Execution tracking
  execution_tracking:
    phase_start_times: {}
    phase_end_times: {}
    agent_invocations: []  # Record of all Task tool invocations
    error_history: []      # Record of failures and recoveries
    debug_iteration: 0     # Current debugging iteration (max 3)

  # Performance metrics
  performance_metrics:
    total_duration_seconds: 0
    research_parallelization_savings: 0
    debug_iterations_used: 0
    agents_invoked: 0
    files_created: 0
```

**Step 3: Check for Resumable Checkpoint**

BEFORE starting fresh workflow, check if a checkpoint exists from a previous interrupted orchestration:

```bash
# Check for checkpoint file
if [ -f .claude/checkpoints/orchestrate_latest.checkpoint ]; then
  # Checkpoint exists - ask user if they want to resume
  echo "Found existing orchestration checkpoint. Resume? (y/n)"
  # If yes: load checkpoint state and skip to current_phase
  # If no: proceed with fresh workflow
fi
```

**Verification Checklist**:
- [ ] TodoWrite invoked with all 6 workflow phase tasks
- [ ] workflow_state structure initialized in memory
- [ ] Checkpoint detection performed (resume prompt if checkpoint found)
- [ ] current_phase set to "analysis"
- [ ] Ready to proceed with workflow analysis

## Shared Utilities Integration

### Utility Initialization

Before starting the workflow, initialize all required utilities for consistent error handling, state management, and logging.

**Step 1: Detect Project Directory**
```bash
# Detect project root dynamically
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/detect-project-dir.sh"
# Sets: CLAUDE_PROJECT_DIR
```

**Step 2: Source Required Utilities**
```bash
UTILS_DIR="$CLAUDE_PROJECT_DIR/.claude/lib"

# Verify utilities exist
[ -f "$UTILS_DIR/error-handling.sh" ] || { echo "ERROR: error-handling.sh not found"; exit 1; }
[ -f "$UTILS_DIR/checkpoint-utils.sh" ] || { echo "ERROR: checkpoint-utils.sh not found"; exit 1; }

# Source utilities
source "$UTILS_DIR/error-handling.sh"
source "$UTILS_DIR/checkpoint-utils.sh"

echo "✓ Shared utilities initialized"
```

**Available Utilities**:
- **Checkpoint Management**: `.claude/lib/checkpoint-utils.sh` for saving/restoring workflow state
- **Error Handling**: `.claude/lib/error-handling.sh` for agent error recovery and fallback strategies
  - `retry_with_backoff()`: Automatic retry with exponential backoff
  - `classify_error()`: Categorize error types
  - `suggest_recovery()`: Generate recovery suggestions
  - `format_error_report()`: Structured error reporting

These utilities ensure workflow state is preserved across interruptions and agent failures are handled gracefully.

## Error Handling Strategy

**See comprehensive patterns in**: `.claude/docs/reference/orchestration-patterns.md#error-recovery-patterns`

### Error Handling Principles

1. **Agent Invocation Failures**: Use `retry_with_backoff()` from error-handling.sh for automatic retry with exponential backoff
2. **File Creation Failures**: Verify expected files created, retry if missing, search alternative locations
3. **Test Failures**: Enter debugging loop (max 3 iterations), DO NOT treat as errors
4. **Checkpoint Failures**: Graceful degradation - warn user but continue workflow

### Utility Integration

Source required utilities from `.claude/lib/`:
- `error-handling.sh` - retry_with_backoff(), classify_error(), format_error_report(), suggest_recovery()
- `checkpoint-utils.sh` - save_checkpoint(), load_checkpoint()

### Recovery Pattern

```yaml
error_recovery:
  1. Capture error message and context
  2. Classify error type (transient/permanent)
  3. Retry if transient (exponential backoff)
  4. Log to workflow_state.error_history
  5. Escalate to user if unrecoverable
```

See `.claude/docs/reference/orchestration-patterns.md` for detailed implementation examples.

## Progress Streaming

**See comprehensive patterns in**: `.claude/docs/logging-patterns.md#progress-markers`

### Progress Marker Format

Use `PROGRESS:` prefix for all progress messages:
```
PROGRESS: [phase] - [action_description]
```

### When to Emit

- **Phase transitions**: Starting/completing each workflow phase
- **Agent invocations**: Before and after each agent
- **File operations**: Creating/verifying important files (plans, reports, summaries)
- **Long operations**: Every 30s or at natural checkpoints
- **Verification steps**: At completion

### Best Practices

1. Emit before long operations (agent invocations, file reads, bash operations)
2. Include context (phase/agent/file being processed)
3. Use "N/M" format for multi-step operations
4. Use ✓ for successful completions
5. Update TodoWrite BEFORE emitting phase transition markers

See `.claude/docs/logging-patterns.md` for detailed examples and patterns.

### Step 1: Parse Workflow Description

YOU MUST extract:
- **Core Feature/Task**: What needs to be accomplished
- **Workflow Type**: Feature development, refactoring, debugging, or investigation
- **Complexity Indicators**: Keywords suggesting scope and approach
- **Parallelization Hints**: Tasks eligible for concurrent execution

### Step 2: Identify Workflow Phases

Based on the description, YOU MUST determine which phases are needed:

**Standard Development Workflow**:
1. **Research Phase** (Parallel): Investigate patterns, best practices, alternatives
2. **Planning Phase** (Sequential): Synthesize findings into structured plan
3. **Implementation Phase** (Adaptive): Execute plan with testing
4. **Debugging Loop** (Conditional): Fix failures if tests don't pass
5. **Documentation Phase** (Sequential): Update docs and generate summary

**Simplified Workflows** (for straightforward tasks):
- Skip research if task is well-understood
- Direct to implementation for simple fixes
- Minimal documentation for internal changes

### Step 3: Initialize Workflow State

YOU MUST create minimal orchestrator state:

```yaml
workflow_state:
  workflow_description: "[User's request]"
  workflow_type: "feature|refactor|debug|investigation"
  current_phase: "research|planning|implementation|debugging|documentation"
  completed_phases: []
  project_name: ""  # Auto-generated from workflow description

checkpoints:
  research_complete: null
  plan_ready: null
  implementation_complete: null
  tests_passing: null
  workflow_complete: null

context_preservation:
  research_reports: []  # Paths to created report files
  plan_path: ""
  implementation_status:
    tests_passing: false
    files_modified: []
  debug_reports: []  # Paths to created debug report files
  documentation_paths: []

error_history: []
performance_metrics:
  phase_times: {}
  parallel_effectiveness: 0
```

## Phase Coordination

### Phase 0: Project Location Determination (Foundation)

The location determination phase establishes the foundation for artifact organization by analyzing the workflow request, determining the topic directory location, and creating the directory structure for all subsequent artifacts.

**When to Execute Phase 0**:
- **ALL workflows** - This phase is mandatory for proper artifact organization
- Executes BEFORE research phase
- Uses unified location detection library

**Quick Overview**:
1. Source unified location detection library
2. Library analyzes workflow description to identify affected components
3. Library determines next topic number in specs/ directory
4. Library creates topic directory structure: `specs/NNN_topic/{reports,plans,summaries,debug,scripts,outputs}/`
5. Store location context in workflow variables for injection into all subsequent phases
6. Verify directory structure created successfully

**Artifact Organization**:
- **Purpose**: Ensure all workflow artifacts organized in single topic directory
- **Structure**: `specs/NNN_topic/` with 6 subdirectories
- **Benefits**: Easy navigation, clear artifact ownership, gitignore compliance
- **Integration**: Location context injected into all subsequent subagent prompts

**EXECUTE NOW - Perform Location Detection**

YOU MUST use the unified location detection library to establish artifact organization foundation.

**WHY THIS MATTERS**: Without proper artifact organization, research reports, plans, and debug reports will be scattered across the project. The unified library creates a single topic directory where ALL workflow artifacts will be saved, enabling proper organization and discoverability.

**OPTIMIZATION**: Previously used location-specialist agent (75.6k tokens, 25.2s). Now uses unified library (<11k tokens, <1s) for 85% token reduction and 20x speedup.

```bash
# Feature flag for gradual rollout
USE_UNIFIED_LOCATION="${USE_UNIFIED_LOCATION:-true}"

if [ "$USE_UNIFIED_LOCATION" = "true" ]; then
  # Source unified location detection library
  source "${CLAUDE_CONFIG:-${HOME}/.config}/.claude/lib/unified-location-detection.sh"

  # Perform location detection using unified library
  LOCATION_JSON=$(perform_location_detection "$WORKFLOW_DESCRIPTION" "false")

  # Extract values from JSON output
  if command -v jq &>/dev/null; then
    TOPIC_PATH=$(echo "$LOCATION_JSON" | jq -r '.topic_path')
    TOPIC_NUMBER=$(echo "$LOCATION_JSON" | jq -r '.topic_number')
    TOPIC_NAME=$(echo "$LOCATION_JSON" | jq -r '.topic_name')
    ARTIFACT_REPORTS=$(echo "$LOCATION_JSON" | jq -r '.artifact_paths.reports')
    ARTIFACT_PLANS=$(echo "$LOCATION_JSON" | jq -r '.artifact_paths.plans')
    ARTIFACT_SUMMARIES=$(echo "$LOCATION_JSON" | jq -r '.artifact_paths.summaries')
    ARTIFACT_DEBUG=$(echo "$LOCATION_JSON" | jq -r '.artifact_paths.debug')
    ARTIFACT_SCRIPTS=$(echo "$LOCATION_JSON" | jq -r '.artifact_paths.scripts')
    ARTIFACT_OUTPUTS=$(echo "$LOCATION_JSON" | jq -r '.artifact_paths.outputs')
  else
    # Fallback without jq
    TOPIC_PATH=$(echo "$LOCATION_JSON" | grep -o '"topic_path": *"[^"]*"' | sed 's/.*: *"\([^"]*\)".*/\1/')
    TOPIC_NUMBER=$(echo "$LOCATION_JSON" | grep -o '"topic_number": *"[^"]*"' | sed 's/.*: *"\([^"]*\)".*/\1/')
    TOPIC_NAME=$(echo "$LOCATION_JSON" | grep -o '"topic_name": *"[^"]*"' | sed 's/.*: *"\([^"]*\)".*/\1/')
    ARTIFACT_REPORTS="${TOPIC_PATH}/reports"
    ARTIFACT_PLANS="${TOPIC_PATH}/plans"
    ARTIFACT_SUMMARIES="${TOPIC_PATH}/summaries"
    ARTIFACT_DEBUG="${TOPIC_PATH}/debug"
    ARTIFACT_SCRIPTS="${TOPIC_PATH}/scripts"
    ARTIFACT_OUTPUTS="${TOPIC_PATH}/outputs"
  fi

  # Store in workflow state
  export WORKFLOW_TOPIC_DIR="$TOPIC_PATH"
  export WORKFLOW_TOPIC_NUMBER="$TOPIC_NUMBER"
  export WORKFLOW_TOPIC_NAME="$TOPIC_NAME"

  echo "✓ Location detection completed using unified library"
  echo "  Topic: $TOPIC_PATH"
  echo "  Number: $TOPIC_NUMBER"
  echo "  Name: $TOPIC_NAME"
fi
```

**MANDATORY VERIFICATION - Directory Structure**

After location detection, YOU MUST verify topic directory structure was created correctly.

**VERIFICATION CHECKPOINT:**
```bash
# Verify topic directory exists
if [ ! -d "$TOPIC_PATH" ]; then
  echo "❌ ERROR: Location detection failed - topic directory not created at $TOPIC_PATH"
  echo "FALLBACK: Creating directory structure manually"

  # Fallback: Create directory structure manually
  mkdir -p "$TOPIC_PATH"/{reports,plans,summaries,debug,scripts,outputs}

  if [ $? -eq 0 ]; then
    echo "✓ Fallback successful: Directory structure created manually"
  else
    echo "✗ CRITICAL FAILURE: Cannot create directory structure"
    echo "Please check permissions and disk space at: $TOPIC_PATH"
    exit 1
  fi
fi

# Verify all required subdirectories exist
MISSING_SUBDIRS=()
for subdir in reports plans summaries debug scripts outputs; do
  if [ ! -d "$TOPIC_PATH/$subdir" ]; then
    echo "⚠ WARNING: Missing subdirectory $TOPIC_PATH/$subdir - creating"
    mkdir -p "$TOPIC_PATH/$subdir"
    if [ $? -ne 0 ]; then
      MISSING_SUBDIRS+=("$subdir")
    fi
  fi
done

if [ ${#MISSING_SUBDIRS[@]} -gt 0 ]; then
  echo "✗ ERROR: Failed to create subdirectories: ${MISSING_SUBDIRS[*]}"
  exit 1
fi

echo "✓ Verification complete: Topic directory structure validated at $TOPIC_PATH"
```
End verification. Proceed only if directory structure exists.

**Phase 0 Completion Summary**

Display Phase 0 summary to user:

```
═══════════════════════════════════════════════════════
✓ Phase 0: Project Location Determination Complete
═══════════════════════════════════════════════════════

Topic: ${TOPIC_NUMBER}_${TOPIC_NAME}
Location: ${TOPIC_PATH}

Artifact Paths Configured:
 - Reports: ${ARTIFACT_REPORTS}
 - Plans: ${ARTIFACT_PLANS}
 - Summaries: ${ARTIFACT_SUMMARIES}
 - Debug: ${ARTIFACT_DEBUG} (committed to git)
 - Scripts: ${ARTIFACT_SCRIPTS} (temporary)
 - Outputs: ${ARTIFACT_OUTPUTS} (test results)

All subsequent phases will save artifacts to this topic directory.

Next Phase: Research
═══════════════════════════════════════════════════════
```

**Checkpoint: Phase 0 Complete**

Mark Phase 0 as complete in workflow state:
```yaml
workflow_state:
  phase: 1  # Ready for Research phase
  location_context:
    topic_path: "${TOPIC_PATH}"
    topic_number: "${TOPIC_NUMBER}"
    topic_name: "${TOPIC_NAME}"
    artifact_paths: { ... }
  research_reports: []  # Will be populated in Phase 1
  overview_report: null  # Will be populated in Phase 2
  plan_path: null        # Will be populated in Phase 2
```

---

### Research Phase (Parallel Execution)

The research phase coordinates multiple specialized agents to investigate different aspects of the workflow in parallel, then verifies all research outputs before proceeding.

**When to Use Research Phase**:
- **Complex workflows** requiring investigation of existing patterns, best practices, alternatives, or constraints
- **Medium+ complexity** (keywords: "implement", "add with research", "redesign", "architecture")
- **Skip for simple tasks** (keywords: "fix", "update single file", "small change")

**Quick Overview**:
1. Analyze workflow complexity and determine thinking mode
2. Identify 2-4 research topics based on complexity
3. Launch research-specialist agents in parallel (single message, multiple Task calls)
4. Monitor agent execution and collect report paths
5. Verify reports exist at expected paths (with automatic path mismatch recovery)
6. Save checkpoint with research outputs

**Pattern Details**: See [Orchestration Patterns - Research Phase](../templates/orchestration-patterns.md#research-phase-parallel-execution) for:
- Complete step-by-step execution procedure (7 detailed steps)
- Complexity score calculation algorithm
- Thinking mode determination matrix
- Absolute path calculation requirements
- Parallel agent invocation patterns
- Progress monitoring and PROGRESS: marker standards
- Report verification and error recovery procedures
- Checkpoint creation and state management
- Full workflow example with timing metrics

**Key Execution Requirements**:

1. **Complexity Analysis** (Step 1.5):
   ```
   score = keywords("implement"/"architecture") × 3
         + keywords("add"/"improve") × 2
         + keywords("security"/"breaking") × 4
         + estimated_files / 5
         + (research_topics - 1) × 2

   Thinking Mode:
   - 0-3: standard (no special mode)
   - 4-6: "think" (moderate)
   - 7-9: "think hard" (complex)
   - 10+: "think harder" (critical)
   ```

**EXECUTE NOW - Calculate Report Paths** (Step 2: Before Agent Invocation)

BEFORE invoking research agents, calculate absolute report paths for each research topic.

**Required Preparation**:

```bash
# Source required utilities
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-creation.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-registry.sh"

# Identify research topics from workflow description
# Number of topics based on complexity:
#   - Low complexity (score 0-3): 0-1 topics (skip research)
#   - Medium complexity (score 4-6): 2 topics
#   - High complexity (score 7-9): 3 topics
#   - Critical complexity (score 10+): 4 topics
```

**Example: Extracting Research Topics from Workflow**:

```bash
# Example workflow description
WORKFLOW="Add user authentication with OAuth2 and session management"

# Identify research topics based on complexity
# For this workflow (complexity ~8): 3 topics
TOPICS=(
  "authentication_patterns"    # OAuth2 implementation patterns
  "session_management"          # Session storage and lifecycle
  "security_best_practices"     # Auth security considerations
)

echo "Identified ${#TOPICS[@]} research topics for workflow"
```

<!--
ENFORCEMENT RATIONALE: Path Pre-Calculation

WHY "EXECUTE NOW" instead of "First, create":
- Without "EXECUTE NOW", Claude interprets this as guidance, not requirement
- ~30% of runs skip path calculation when using descriptive language
- Skipping causes agents to create files in wrong locations (or not at all)
- Explicit "EXECUTE NOW" + verification checkpoint = 100% execution rate

BEFORE: "First, create..." (60-70% compliance)
AFTER: "**EXECUTE NOW** - YOU MUST create" (100% compliance)
-->

**EXECUTE NOW - Calculate Report Paths BEFORE Agent Invocation**

YOU MUST execute this code block BEFORE invoking research agents. This is NOT optional guidance.

**WHY THIS MATTERS**: Agents need EXACT absolute paths to prevent path mismatch errors. If you skip this step, agents will create files in wrong locations or not at all.

**VERIFICATION REQUIREMENT**: After executing this block, you MUST confirm all paths are absolute and stored in REPORT_PATHS array.

```bash
# MANDATORY: Create workflow topic directory
# This centralizes all artifacts (reports, plans, summaries) for this workflow
source "${CLAUDE_PROJECT_DIR}/.claude/lib/template-integration.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-creation.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/metadata-extraction.sh"

WORKFLOW_TOPIC_DIR=$(get_or_create_topic_dir "$WORKFLOW_DESCRIPTION" ".claude/specs")
echo "Workflow topic directory: $WORKFLOW_TOPIC_DIR"

# Example topics (adapt based on workflow):
TOPICS=("existing_patterns" "best_practices" "integration_approaches")

# MANDATORY: Calculate absolute paths for each topic
declare -A REPORT_PATHS

for topic in "${TOPICS[@]}"; do
  # Use create_topic_artifact() to create report with proper numbering
  # This ensures topic-based organization: specs/{NNN_workflow}/reports/NNN_topic.md
  REPORT_PATH=$(create_topic_artifact "$WORKFLOW_TOPIC_DIR" "reports" "${topic}" "")

  # Store in associative array
  REPORT_PATHS["$topic"]="$REPORT_PATH"

  echo "  Research Topic: $topic"
  echo "  Report Path: $REPORT_PATH"
done
```

**MANDATORY VERIFICATION - Path Pre-Calculation Complete**

After executing the path calculation block, YOU MUST verify:

```bash
# Verification: Check all paths are absolute
for topic in "${!REPORT_PATHS[@]}"; do
  if [[ ! "${REPORT_PATHS[$topic]}" =~ ^/ ]]; then
    echo "CRITICAL ERROR: Path for '$topic' is not absolute: ${REPORT_PATHS[$topic]}"
    exit 1
  fi
done

echo "✓ VERIFIED: All paths are absolute"
echo "✓ VERIFIED: ${#REPORT_PATHS[@]} report paths calculated"
echo "✓ VERIFIED: Ready to invoke research agents"
```

**CHECKPOINT REQUIREMENT**: Report completion before proceeding:
```
CHECKPOINT: Path pre-calculation complete
- Topics identified: ${#TOPICS[@]}
- Report paths calculated: ${#REPORT_PATHS[@]}
- All paths verified: ✓
- Proceeding to: Agent invocation
```

<!--
ENFORCEMENT RATIONALE: Agent Template Verbatim Usage

WHY "THIS EXACT TEMPLATE" instead of "Example":
- When prompt says "example", Claude paraphrases/simplifies 60-80% of time
- Simplified prompts remove enforcement markers ("ABSOLUTE REQUIREMENT", "STEP 1")
- Without enforcement markers, agents treat file creation as optional
- Result: 20-40% file creation rate with simplified prompts

WHY fallback mechanism isn't enough alone:
- We want agents to succeed (proper structure, metadata, content)
- Fallback creates minimal report from agent output (suboptimal)
- Exact template + fallback = high success + safety net

BEFORE: "Example:" (agents simplify, 20-40% file creation)
AFTER: "**THIS EXACT TEMPLATE (No modifications)**" (60-80% agent compliance + 100% with fallback)
-->

**AGENT INVOCATION - Use THIS EXACT TEMPLATE (No modifications)**

**CRITICAL INSTRUCTION**: The agent prompt below is NOT an example or suggestion. It is the EXACT template you MUST use when invoking research agents. Do NOT:
- Simplify the language
- Remove any "ABSOLUTE REQUIREMENT" markers
- Paraphrase the instructions
- Skip any sections
- Change the structure

**WHY THIS MATTERS**: Research agents need explicit enforcement markers to guarantee file creation. If you simplify this prompt, agents will treat file creation as optional, leading to 0% success rate.

**ENFORCEMENT CHECKPOINT**: Before invoking agents, confirm you will use this EXACT prompt template without modifications.

---

**EXACT AGENT PROMPT TEMPLATE** (Copy verbatim for EACH research agent):

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Research [TOPIC] with mandatory artifact creation"
  timeout: 300000  # 5 minutes per research agent
  prompt: "
    **ABSOLUTE REQUIREMENT - File Creation is Your Primary Task**

    Creating the report file is NOT optional. It is your PRIMARY task. Follow these steps IN ORDER:

    **STEP 1: CREATE THE FILE** (Do this FIRST, before any research)
    Use the Write tool to create a report file at this EXACT path:
    **Report Path**: ${ARTIFACT_REPORTS}${TOPIC_NUMBER}_research_[TOPIC_NAME].md

    **ARTIFACT ORGANIZATION** (CRITICAL - From Phase 0 Location Context):
    - Save report to artifact directory: ${ARTIFACT_REPORTS}
    - Filename format: ${TOPIC_NUMBER}_research_[TOPIC_NAME].md
    - Example: If topic number is 027 and topic is oauth_patterns, filename is 027_research_oauth_patterns.md
    - Full path example: /home/user/.config/specs/027_auth/reports/027_research_oauth_patterns.md
    - DO NOT use relative paths
    - DO NOT save to arbitrary locations
    - MUST use absolute path from location context

    **CRITICAL**: Use Write tool NOW. Do not wait until after research. Create the file FIRST with initial structure, then fill in findings.

    **STEP 2: CONDUCT RESEARCH**
    Analyze [SPECIFIC RESEARCH FOCUS FOR THIS TOPIC]:
    1. [Specific search pattern 1]
    2. [Specific analysis requirement 2]
    3. [Specific documentation requirement 3]
    4. [Specific recommendation requirement 4]

    Write your findings DIRECTLY into the report file created in Step 1.

    **STEP 3: RETURN CONFIRMATION**
    After completing Steps 1 and 2, return ONLY this confirmation (no summary):
    \`\`\`
    REPORT_CREATED: ${ARTIFACT_REPORTS}${TOPIC_NUMBER}_research_[TOPIC_NAME].md
    \`\`\`

    **CRITICAL REQUIREMENTS** (Non-Negotiable):
    - DO NOT return summary text. Orchestrator will read your report file.
    - DO NOT use relative paths or calculate paths yourself
    - DO NOT skip file creation - it is mandatory
    - DO NOT wait to create file - do it in STEP 1
    - Use Write tool with the EXACT path provided above
    - File MUST exist at specified path when you return
    - File MUST be in ${ARTIFACT_REPORTS} directory
  "
}
```

**VARIABLES TO REPLACE** (These are the ONLY parts you modify):
- `[TOPIC]`: Replace with topic name (e.g., "oauth_patterns")
- `[TOPIC_NAME]`: Replace with sanitized topic name matching [TOPIC] (e.g., "oauth_patterns")
- `[SPECIFIC RESEARCH FOCUS FOR THIS TOPIC]`: Replace with topic-specific research requirements
- `[Specific search pattern N]`: Replace with specific search/analysis steps for this topic

**AUTOMATIC SUBSTITUTION FROM PHASE 0** (DO NOT manually replace these):
- `${ARTIFACT_REPORTS}`: Absolute path to reports directory from location context
- `${TOPIC_NUMBER}`: 3-digit topic number from location context (e.g., "027")
- These variables are set in Phase 0 and available in workflow state

**ENFORCEMENT VERIFICATION**: After replacing variables, confirm:
- [ ] All enforcement markers preserved ("ABSOLUTE REQUIREMENT", "CRITICAL", "STEP 1", etc.)
- [ ] No language simplified or paraphrased
- [ ] Structure identical to template
- [ ] Only specified variables replaced

**EXECUTE NOW - Research Phase with Auto-Retry**

The research phase invokes agents with automatic retry on failure. Each topic is attempted up to 3 times with escalating template enforcement.

**Auto-Retry Wrapper Function**

For each research topic, invoke agents with retry logic:

```bash
# Research phase with auto-retry and degraded continuation
declare -a SUCCESSFUL_REPORTS=()
declare -a FAILED_TOPICS=()

for topic in "${!REPORT_PATHS[@]}"; do
  echo ""
  echo "=== Researching: $topic ==="

  max_attempts=3
  success=false

  for attempt in $(seq 1 $max_attempts); do
    # Select template based on attempt number
    if [ $attempt -eq 1 ]; then
      template="standard"
      echo "Invoking research agent for '$topic' (attempt $attempt/$max_attempts, template: $template)"
      # Use STANDARD template
    elif [ $attempt -eq 2 ]; then
      template="ultra_explicit"
      echo "⚠️  Attempt 1 failed. Retrying with ultra-explicit enforcement (attempt $attempt/$max_attempts)"
      # Use ULTRA-EXPLICIT template
    else
      template="step_by_step"
      echo "⚠️  Attempt 2 failed. Final retry with step-by-step enforcement (attempt $attempt/$max_attempts)"
      # Use STEP-BY-STEP template
    fi

    # Invoke research agent with selected template
    REPORT_PATH="${REPORT_PATHS[$topic]}"
    TOPIC="$topic"

    case "$template" in
      standard)
        # STANDARD TEMPLATE - Attempt 1
        Task {
          subagent_type: "general-purpose"
          description: "Research ${TOPIC} with mandatory artifact creation"
          timeout: 300000
          prompt: "
            **FILE CREATION REQUIRED**

            Use Write tool to create: ${REPORT_PATH}

            Research ${TOPIC} and document findings in the file.

            Return only: REPORT_CREATED: ${REPORT_PATH}
          "
        }
        ;;

      ultra_explicit)
        # ULTRA-EXPLICIT TEMPLATE - Attempt 2
        Task {
          subagent_type: "general-purpose"
          description: "Research ${TOPIC} - RETRY with ultra-explicit enforcement"
          timeout: 300000
          prompt: "
            **CRITICAL: You MUST create a file. This is NON-NEGOTIABLE.**

            **STEP 1 - CREATE FILE NOW**
            Use the Write tool RIGHT NOW with this exact path:
            ${REPORT_PATH}

            **STEP 2 - RESEARCH**
            Research ${TOPIC} thoroughly and document in the file.

            **STEP 3 - RETURN CONFIRMATION ONLY**
            Return ONLY this text: REPORT_CREATED: ${REPORT_PATH}

            **PROHIBITED**: Do NOT return summaries or findings in your response.
          "
        }
        ;;

      step_by_step)
        # STEP-BY-STEP TEMPLATE - Attempt 3
        Task {
          subagent_type: "general-purpose"
          description: "Research ${TOPIC} - FINAL RETRY with step verification"
          timeout: 300000
          prompt: "
            **EXECUTE IMMEDIATELY: File creation is your PRIMARY and ONLY deliverable**

            **ACTION 1: CREATE THE FILE**
            Use Write tool NOW: ${REPORT_PATH}
            Initial content: '# Research Report: ${TOPIC}'

            **ACTION 2: VERIFY FILE CREATED**
            Use Read tool to confirm file exists: ${REPORT_PATH}

            **ACTION 3: CONDUCT RESEARCH**
            Research ${TOPIC} using Grep/Glob/Read tools

            **ACTION 4: UPDATE FILE**
            Use Edit tool to add findings to ${REPORT_PATH}

            **ACTION 5: FINAL VERIFICATION**
            Use Read tool to verify content exists

            **ACTION 6: RETURN CONFIRMATION**
            Return ONLY: REPORT_CREATED: ${REPORT_PATH}

            **CRITICAL**: If you skip any action, you will fail. Each action is MANDATORY.
          "
        }
        ;;
    esac

    # After agent returns, check if file was created
    EXPECTED_PATH="${REPORT_PATHS[$topic]}"

    if [ -f "$EXPECTED_PATH" ]; then
      # Validate file has content
      if [ -s "$EXPECTED_PATH" ]; then
        echo "  ✓ Success on attempt $attempt (template: $template)"
        SUCCESSFUL_REPORTS+=("$EXPECTED_PATH")
        success=true
        break
      else
        echo "  ⚠️  File created but empty, retrying..."
        rm "$EXPECTED_PATH"  # Clean up empty file
      fi
    else
      echo "  ⚠️  File not created by agent"
    fi

    if [ $attempt -lt $max_attempts ]; then
      echo "  Retrying with enhanced enforcement..."
    fi
  done

  if [ "$success" = false ]; then
    echo "  ❌ All $max_attempts retry attempts failed for topic: $topic"
    FAILED_TOPICS+=("$topic")
    echo "  Continuing to next topic..."
  fi
done

# Check if we have at least one report
if [ ${#SUCCESSFUL_REPORTS[@]} -eq 0 ]; then
  echo ""
  echo "❌ CRITICAL: No research reports created - cannot proceed to planning"
  echo "All topics failed: ${!REPORT_PATHS[@]}"
  exit 1
fi

# Show summary before proceeding
echo ""
echo "=== RESEARCH PHASE SUMMARY ==="
echo "Successful: ${#SUCCESSFUL_REPORTS[@]}/${#REPORT_PATHS[@]} topics"
if [ ${#FAILED_TOPICS[@]} -gt 0 ]; then
  echo "⚠️  Failed topics: ${FAILED_TOPICS[@]}"
  echo "Proceeding to planning with partial results..."
fi
```

**Implementation Instructions**

When executing research phase, YOU MUST:

1. **Iterate through topics**: Process each topic in REPORT_PATHS
2. **Retry loop**: For each topic, attempt up to 3 times
3. **Template selection**:
   - Attempt 1: Use STANDARD template
   - Attempt 2: Use ULTRA-EXPLICIT template
   - Attempt 3: Use STEP-BY-STEP template
4. **File verification**: After each attempt, check file exists and has content
5. **Success tracking**: Add successful paths to SUCCESSFUL_REPORTS array
6. **Failure tracking**: Add failed topics to FAILED_TOPICS array
7. **Degraded continuation**: Continue to next topic if all retries fail
8. **Critical check**: Exit if NO reports created (need at least one)

**MANDATORY: Parallel Invocation for First Attempt**

For the FIRST attempt (standard template), invoke ALL research agents in parallel in a SINGLE message:

**CORRECT PATTERN** (Required for Attempt 1):
```
Message to Claude Code:
I'm invoking 3 research agents in parallel (attempt 1, standard template):

Task { [topic 1 with STANDARD template] }
Task { [topic 2 with STANDARD template] }
Task { [topic 3 with STANDARD template] }
```

For retries (attempts 2-3), invoke agents sequentially as failures are discovered.

**VERIFICATION BEFORE INVOCATION**:
- [ ] All agent prompts use EXACT template for current attempt
- [ ] All REPORT_PATHS replaced with absolute paths
- [ ] First attempt uses SINGLE message with all Task calls
- [ ] Retry attempts use selected enforcement template
- [ ] No enforcement markers removed

<!--
ENFORCEMENT RATIONALE: Mandatory Verification + Fallback

WHY "MANDATORY VERIFICATION" instead of "Verify that":
- Descriptive "verify that" sounds advisory, Claude WILL skip
- ~20% of runs skip verification when not marked mandatory
- Without verification, missing files go undetected
- Without fallback trigger, 0% success when agent doesn't comply

WHY fallback mechanism is "GUARANTEED":
- Primary path: Agent creates file (60-80% success with exact template)
- Fallback path: Orchestrator creates file from agent output (100% success)
- Combined: 100% file creation rate

BEFORE: "Verify that files were created" (80% execution, 0% fallback)
AFTER: "**MANDATORY VERIFICATION**" + fallback (100% execution, 100% creation)
-->

**Auto-Recovery Architecture - No Fallback Mechanisms**

**DESIGN CHANGE**: This orchestrator uses strict subagent-only operation with auto-recovery.

**How Verification Works Now**:
1. **Auto-Retry**: Research phase automatically retries each topic up to 3 times with escalating enforcement
2. **File Validation**: Built into retry loop - checks file exists and has content after each attempt
3. **Degraded Continuation**: Topics that fail all 3 attempts are added to FAILED_TOPICS array
4. **Workflow Continues**: Planning proceeds with SUCCESSFUL_REPORTS (requires at least one)
5. **NO Orchestrator Fallback**: Orchestrator NEVER creates files - only subagents create artifacts

**What Was Removed**:
- Orchestrator fallback file creation (`cat > "$PATH" <<EOF`)
- Post-hoc verification with fallback triggers
- Manual file creation from agent outputs
- Path correction mechanisms

**Why This Is Better**:
1. **Single Responsibility**: Subagents create files, orchestrator verifies
2. **Immediate Failure Detection**: No hidden compensations masking agent issues
3. **Simpler Code**: No dual-path logic (primary + fallback)
4. **Clear Success/Failure**: Workflow summary shows exactly what succeeded and failed
5. **User Visibility**: Failed topics explicitly reported, not silently created by orchestrator

**Recovery Strategy**:
- Retry with escalation (standard → ultra-explicit → step-by-step)
- Maximum 3 attempts per topic before marking as failed
- Workflow continues with partial results (degraded continuation)
- Planning requires at least 1 successful report to proceed

---

**EXECUTE NOW - Synthesize Individual Reports into Overview** (Phase 2: Research Synthesis)

After all individual reports are verified, invoke research-synthesizer to create overview report aggregating findings.

**WHY THIS MATTERS**: Overview report provides unified synthesis of all research findings, enabling plan-architect to consume single coherent document instead of multiple individual reports. Reduces planning phase complexity and improves plan coherence.

**EXECUTE NOW - Invoke research-synthesizer Agent**:

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Synthesize individual research reports into overview"
  timeout: 300000  # 5 minutes for synthesis
  prompt: |
    Read and follow the behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-synthesizer.md

    You are acting as a Research Synthesizer Agent.

    OPERATION: Aggregate individual research reports into comprehensive overview

    Individual Report Paths:
    ${RESEARCH_REPORT_PATHS_FORMATTED}

    Overview Output Path (ABSOLUTE REQUIREMENT):
    ${ARTIFACT_REPORTS}${WORKFLOW_TOPIC_NUMBER}_research_overview.md

    Topic Information:
    - Topic Number: ${WORKFLOW_TOPIC_NUMBER}
    - Topic Name: ${WORKFLOW_TOPIC_NAME}
    - Reports Directory: ${ARTIFACT_REPORTS}

    Tasks:
    1. Read all ${#RESEARCH_REPORT_PATHS[@]} individual reports completely
    2. Extract key findings, recommendations, constraints from each
    3. Identify cross-report patterns and themes
    4. Synthesize into overview with 6 required sections:
       - Executive Summary (3-5 sentences)
       - Cross-Report Findings (patterns across reports)
       - Detailed Findings by Topic (one section per report with link)
       - Recommended Approach (synthesized strategy)
       - Constraints and Trade-offs
       - Individual Report References (navigation links)
    5. Create overview file at EXACT path above using Write tool
    6. Generate 100-word summary for context reduction
    7. Return confirmation with metadata

    Required output format:
    OVERVIEW_CREATED: [absolute path]

    OVERVIEW_SUMMARY:
    [100-word synthesis of all findings]

    METADATA:
    - Reports Synthesized: [N]
    - Cross-Report Patterns: [count]
    - Recommended Approach: [brief description]
    - Critical Constraints: [if any]

    CRITICAL REQUIREMENTS:
    - CREATE overview file at exact path above
    - INCLUDE cross-reference links to all individual reports
    - USE relative paths for links (reports in same directory)
    - RETURN 100-word summary (not full content)
    - DO NOT skip reading any individual reports
}
```

**MANDATORY VERIFICATION - Overview Report Created**

After research-synthesizer completes, YOU MUST verify overview was created.

```bash
# Extract overview path from agent output
OVERVIEW_OUTPUT="$SYNTHESIZER_AGENT_OUTPUT"
OVERVIEW_PATH=$(echo "$OVERVIEW_OUTPUT" | grep -oP 'OVERVIEW_CREATED:\s*\K/.+' | head -1)

if [ -z "$OVERVIEW_PATH" ]; then
  echo "⚠️  WARNING: Agent did not return OVERVIEW_CREATED confirmation"
  echo "Falling back to expected path"
  OVERVIEW_PATH="${ARTIFACT_REPORTS}${WORKFLOW_TOPIC_NUMBER}_research_overview.md"
fi

echo "✓ Overview path: $OVERVIEW_PATH"

# Verify file exists
if [ ! -f "$OVERVIEW_PATH" ]; then
  echo "❌ ERROR: Overview report not created at $OVERVIEW_PATH"
  echo "FALLBACK: Creating minimal overview template"

  cat > "$OVERVIEW_PATH" <<EOF
# Research Overview

## Metadata
- **Date**: $(date -u +%Y-%m-%d)
- **Agent**: research-synthesizer (fallback)
- **Topic Number**: ${WORKFLOW_TOPIC_NUMBER}
- **Individual Reports**: ${#RESEARCH_REPORT_PATHS[@]} reports

## Executive Summary
Research synthesis not completed by agent. Please review individual reports:

## Individual Report References
EOF

  # Add links to individual reports
  for report_path in "${RESEARCH_REPORT_PATHS[@]}"; do
    filename=$(basename "$report_path")
    echo "- [$filename](./$filename)" >> "$OVERVIEW_PATH"
  done

  if [ ! -f "$OVERVIEW_PATH" ]; then
    echo "❌ CRITICAL: Fallback overview creation failed"
    exit 1
  fi

  echo "✓ FALLBACK: Minimal overview created"
fi

echo "✓ VERIFIED: Overview report exists at $OVERVIEW_PATH"

# Extract 100-word summary from agent output
OVERVIEW_SUMMARY=$(echo "$OVERVIEW_OUTPUT" | sed -n '/OVERVIEW_SUMMARY:/,/METADATA:/p' | sed '1d;$d' | tr '\n' ' ')

if [ -z "$OVERVIEW_SUMMARY" ]; then
  echo "⚠️  WARNING: No summary provided by agent"
  OVERVIEW_SUMMARY="Research overview synthesized from ${#RESEARCH_REPORT_PATHS[@]} individual reports. See overview file for details."
fi

echo "✓ Overview summary extracted (${#OVERVIEW_SUMMARY} chars)"

# Store overview path for planning phase
export RESEARCH_OVERVIEW_PATH="$OVERVIEW_PATH"
export RESEARCH_OVERVIEW_SUMMARY="$OVERVIEW_SUMMARY"
```

**CHECKPOINT - Research Synthesis Complete**:
```
CHECKPOINT: Research synthesis complete
- Individual reports: ${#RESEARCH_REPORT_PATHS[@]}
- Overview created: ✓
- Overview path: $OVERVIEW_PATH
- Summary extracted: ✓
- Proceeding to: Planning phase with overview reference
```

---

**EXECUTE NOW - Extract Metadata from Research Reports** (After Verification Complete)

Now that ALL report files are guaranteed to exist (100% verified), extract metadata for context passing to planning phase.

**WHY THIS MATTERS**: Metadata extraction (title + 50-word summary) reduces context by 99% compared to passing full report content. This enables complex workflows to stay under 30% context usage.

**EXECUTE NOW - Metadata Extraction**:

```bash
# Source metadata extraction utilities
source "${CLAUDE_PROJECT_DIR}/.claude/lib/metadata-extraction.sh"

# Extract metadata from each verified report
declare -A REPORT_METADATA

for topic in "${!AGENT_REPORT_PATHS[@]}"; do
  REPORT_PATH="${AGENT_REPORT_PATHS[$topic]}"

  echo "Extracting metadata from: $REPORT_PATH"

  # Extract title, summary, key findings (NOT full content)
  METADATA=$(extract_report_metadata "$REPORT_PATH")

  # Store metadata (lightweight reference, not full content)
  REPORT_METADATA["$topic"]="$METADATA"

  echo "  ✓ Metadata extracted for: $topic"
done

echo "✓ Metadata extracted from ${#REPORT_METADATA[@]} reports"
```

**METADATA STRUCTURE** (What gets passed to planning phase):

For each report, pass ONLY:
- Report path (absolute reference)
- Title (1 line)
- Summary (max 50 words)
- Key findings (3-5 bullet points, ~30 words total)

**DO NOT PASS**: Full report content (this bloats context)

**VERIFICATION**:
- [ ] Metadata extracted from all ${#AGENT_REPORT_PATHS[@]} reports
- [ ] Each metadata block < 100 words
- [ ] Total metadata size < 1000 words (vs ~5000+ for full content)
- [ ] Report paths included (planning phase will read full content if needed)

**CHECKPOINT REQUIREMENT**:
```
CHECKPOINT: Metadata extraction complete
- Reports processed: ${#AGENT_REPORT_PATHS[@]}
- Metadata extracted: ${#REPORT_METADATA[@]}
- Total metadata size: ~[N] words (99% reduction vs full content)
- Context usage: <10% (research phase complete)
- Proceeding to: Final research checkpoint
```

---

## Research Phase Complete

<!--
ENFORCEMENT RATIONALE: Checkpoint Reporting

WHY checkpoint reporting is mandatory:
- Provides clear progress indicators (user knows phase complete)
- Documents critical metrics (file creation rate, context usage)
- Creates audit trail (debugging failed workflows)
- Confirms all enforcement patterns executed

Without checkpoints:
- User unsure if phase complete
- No metrics for debugging
- Silent failures possible

BEFORE: No checkpoint (unclear status)
AFTER: Mandatory checkpoint (clear status, metrics, audit trail)
-->

**CHECKPOINT REQUIREMENT - Report Research Phase Completion**

Before proceeding to planning phase, YOU MUST report this checkpoint:

```
═══════════════════════════════════════════════════════
CHECKPOINT: Research Phase Complete
═══════════════════════════════════════════════════════

Phase Status: COMPLETE ✓

Research Execution:
- Topics researched: ${#TOPICS[@]}
- Research agents invoked: ${#TOPICS[@]}
- Parallel execution: ✓ (all agents in single message)
- Agent timeout: 5 minutes each
- Total research time: ~[N] minutes

File Creation (Critical Metric):
- Reports expected: ${#REPORT_PATHS[@]}
- Reports created by agents: [N]
- Reports created by fallback: [N]
- Total reports verified: ${#AGENT_REPORT_PATHS[@]}
- File creation rate: 100% ✓

Verification Results:
- Path pre-calculation: ✓ Executed
- Agent template compliance: ✓ Exact template used
- File existence checks: ✓ All passed
- Fallback mechanism: ✓ Triggered [N] times
- Metadata extraction: ✓ Complete

Context Management:
- Full report content: NOT passed to planning
- Metadata extracted: ✓ (titles + summaries only)
- Context usage: <10% (research phase)
- Context reduction: 99% (metadata vs full content)

Artifacts Created:
[List all report paths]

Next Phase: Planning
- Will receive: Report metadata (not full content)
- Will use: /plan command with report references
- Expected: Plan file created in ${WORKFLOW_TOPIC_DIR}/plans/
═══════════════════════════════════════════════════════
```

**CRITICAL**: This checkpoint is MANDATORY. Do NOT proceed to planning phase without reporting it.

**WHY THIS MATTERS**: Checkpoints provide:
1. Clear progress indicators for user
2. Verification that all critical steps executed
3. Metrics for debugging (file creation rate, context usage)
4. Audit trail for workflow execution

---

**Proceeding to Planning Phase**

After reporting the checkpoint, proceed to planning phase with:
- Report metadata (NOT full content)
- Workflow description
- Topic directory path

The planning phase will read full report content if needed.

---

### Planning Phase (Sequential Execution)

The planning phase synthesizes research findings into a structured implementation plan with clear phases, tasks, and testing requirements.

**When to Use Planning Phase**:
- **All workflows** require a plan (simple plans for simple tasks, detailed plans for complex features)
- Follows research phase (if research was performed) OR starts directly from user request
- Single plan-architect agent execution (not parallel)

**Quick Overview**:
1. Prepare planning context (research reports, user request, thinking mode, standards path)
2. Generate plan-architect agent prompt with all context
3. Invoke plan-architect agent (references plan-architect.md protocol)
4. Extract plan path from agent output and validate plan file
5. Save checkpoint with plan path and metadata
6. Display completion status and proceed to implementation

**Pattern Details**: See [Orchestration Patterns - Planning Phase](../templates/orchestration-patterns.md#planning-phase-sequential-execution) for:
- Complete context extraction procedure
- Planning agent prompt template with all placeholders
- Plan validation checklist and bash verification commands
- Checkpoint creation with plan metadata
- State management and TodoWrite updates
- Full workflow example with timing

**Key Execution Requirements**:

1. **Context Preparation** (Step 1):
   ```yaml
   Planning Context:
     research_reports: [array of paths] OR null  # From research phase
     workflow_description: "[original user request]"
     project_name: "[generated in research or from request]"
     thinking_mode: "[from research phase]" OR null
     claude_md_path: "/path/to/CLAUDE.md"

   Context Injection:
     - Provide report PATHS only (not summaries)
     - Agent uses Read tool to access reports selectively
     - Include thinking mode for consistency
     - No orchestration logic passed to agent
   ```

2. **Agent Invocation** (Step 3):
   - **SINGLE** Task tool invocation (sequential, not parallel)
   - Subagent type: general-purpose
   - Reference: plan-architect.md behavioral guidelines
   - Agent invokes /plan slash command
   - Wait for agent completion before proceeding

**EXECUTE NOW - Generate Implementation Plan**

YOU MUST invoke the /plan command to generate a structured implementation plan. This is NOT optional.

**WHY THIS MATTERS**: The planning phase is critical - it structures all research findings into actionable implementation steps. Skipping or simplifying this step leads to unstructured implementation and likely failure. A well-structured plan is the foundation for successful execution.

**MANDATORY INPUTS**:
- Workflow description (original user request)
- Research report paths (from Research Phase, if completed)
- Project standards file path (CLAUDE.md)
- Thinking mode (for consistency with research)

**EXECUTE NOW - Calculate Topic-Based Plan Path BEFORE Agent Invocation**

**WHY THIS MATTERS**: The plan must be created in the same topic directory as research reports for proper artifact organization. We use the location context from Phase 0 to guarantee correct location.

**VERIFICATION REQUIREMENT**: After executing this block, you MUST confirm PLAN_PATH is absolute and in topic-based structure.

```bash
# Use location context from Phase 0
echo "Planning phase starting..."
echo "Topic directory: $WORKFLOW_TOPIC_DIR"
echo "Topic number: $WORKFLOW_TOPIC_NUMBER"

# Calculate plan path using artifact paths from Phase 0 location context
# Format: ${ARTIFACT_PLANS}${TOPIC_NUMBER}_implementation.md
PLAN_PATH="${ARTIFACT_PLANS}${WORKFLOW_TOPIC_NUMBER}_implementation.md"

echo "Plan path calculated: $PLAN_PATH"

# Verify path is absolute
if [[ ! "$PLAN_PATH" =~ ^/ ]]; then
  echo "❌ CRITICAL ERROR: Plan path is not absolute: $PLAN_PATH"
  exit 1
fi

# Verify plan will be in correct artifact directory
if [[ "$PLAN_PATH" != "$ARTIFACT_PLANS"* ]]; then
  echo "❌ CRITICAL ERROR: Plan path not in artifact plans directory"
  echo "  Expected directory: $ARTIFACT_PLANS"
  echo "  Plan path: $PLAN_PATH"
  exit 1
fi

echo "✓ VERIFIED: Plan path is absolute and in artifact plans directory"
```

**CHECKPOINT - Path Pre-Calculation Complete**:
```
CHECKPOINT: Plan path calculated
- Topic directory: [WORKFLOW_TOPIC_DIR]
- Plan path: [PLAN_PATH]
- Path is absolute: ✓
- Topic-based structure: ✓
- Ready to invoke: plan-architect agent
```

**EXECUTE NOW - Invoke plan-architect Agent with Auto-Retry**

**WHY THIS MATTERS**: Planning is critical for workflow success. Auto-retry with escalating enforcement ensures plan file creation even if first attempt fails.

**Auto-Retry Logic for Planning**

Planning phase attempts up to 3 times with escalating template enforcement. Unlike research (which continues with partial results), planning MUST succeed for workflow to continue.

```bash
# Prepare planning context
echo "Preparing planning context..."

# Extract workflow description from arguments (first argument to /orchestrate)
WORKFLOW_DESCRIPTION="$1"

# Build research reports list from SUCCESSFUL_REPORTS array
RESEARCH_REPORTS_LIST=""
if [ ${#SUCCESSFUL_REPORTS[@]} -gt 0 ]; then
  RESEARCH_REPORTS_LIST="Research Reports (MANDATORY - include all in plan metadata):"
  local idx=1
  for report_path in "${SUCCESSFUL_REPORTS[@]}"; do
    # Extract report title from file
    report_title=$(grep "^# " "$report_path" | head -1 | sed 's/^# //' 2>/dev/null || echo "Report $idx")
    RESEARCH_REPORTS_LIST+="
  ${idx}. ${report_title}: ${report_path}"
    ((idx++))
  done
else
  RESEARCH_REPORTS_LIST="No research reports (create plan from workflow description only)"
fi

# Get standards file path
STANDARDS_FILE="${CLAUDE_PROJECT_DIR}/CLAUDE.md"
if [ ! -f "$STANDARDS_FILE" ]; then
  STANDARDS_FILE="Not found - use language-specific defaults"
fi

# Get current working directory for agent behavioral injection
CLAUDE_PROJECT_DIR="$(pwd)"

echo "✓ Planning context prepared"
echo "  - Plan path: $PLAN_PATH"
echo "  - Research reports: ${#SUCCESSFUL_REPORTS[@]}"
echo "  - Workflow: $WORKFLOW_DESCRIPTION"
echo "  - Standards: $STANDARDS_FILE"

# Planning phase with auto-retry
echo ""
echo "Planning phase starting with auto-retry..."

max_attempts=3
plan_created=false

for attempt in $(seq 1 $max_attempts); do
  # Select template based on attempt number
  if [ $attempt -eq 1 ]; then
    template="standard"
    echo "Invoking plan-architect (attempt $attempt/$max_attempts, template: $template)"
    # Use STANDARD template from Auto-Recovery Agent Templates
  elif [ $attempt -eq 2 ]; then
    template="ultra_explicit"
    echo "⚠️  Attempt 1 failed. Retrying with ultra-explicit enforcement (attempt $attempt/$max_attempts)"
    # Use ULTRA-EXPLICIT template from Auto-Recovery Agent Templates
  else
    template="step_by_step"
    echo "⚠️  Attempt 2 failed. Final retry with step-by-step enforcement (attempt $attempt/$max_attempts)"
    # Use STEP-BY-STEP template from Auto-Recovery Agent Templates
  fi

  # Invoke plan-architect agent with selected template
  case "$template" in
    standard)
      # STANDARD TEMPLATE - Attempt 1
      Task {
        subagent_type: "general-purpose"
        description: "Create implementation plan using plan-architect behavioral guidelines"
        timeout: 600000
        prompt: "
          Read and follow behavioral guidelines from:
          ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-architect.md

          You are acting as a Plan Architect Agent with the tools and constraints
          defined in that file.

          **PLAN PATH (MANDATORY - Use this EXACT path)**: ${PLAN_PATH}

          Use Write tool to create: ${PLAN_PATH}

          Create implementation plan for: ${WORKFLOW_DESCRIPTION}

          ${RESEARCH_REPORTS_LIST}

          Standards file: ${STANDARDS_FILE}

          Return only: PLAN_CREATED: ${PLAN_PATH}

          Metadata to include:
          - Phases: [number of phases]
          - Complexity: [Low|Medium|High]
          - Estimated Hours: [total hours]
        "
      }
      ;;

    ultra_explicit)
      # ULTRA-EXPLICIT TEMPLATE - Attempt 2
      Task {
        subagent_type: "general-purpose"
        description: "Create implementation plan - RETRY with ultra-explicit enforcement"
        timeout: 600000
        prompt: "
          Read and follow behavioral guidelines from:
          ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-architect.md

          You are acting as a Plan Architect Agent with the tools and constraints
          defined in that file.

          **CRITICAL: You MUST create a file. This is NON-NEGOTIABLE.**

          **STEP 1 - CREATE FILE NOW**
          Use the Write tool RIGHT NOW with this exact path:
          ${PLAN_PATH}

          **STEP 2 - CREATE PLAN**
          Create comprehensive implementation plan for: ${WORKFLOW_DESCRIPTION}

          ${RESEARCH_REPORTS_LIST}

          Standards file: ${STANDARDS_FILE}

          Follow plan-architect guidelines thoroughly.

          **STEP 3 - RETURN CONFIRMATION ONLY**
          Return ONLY this text: PLAN_CREATED: ${PLAN_PATH}

          Include metadata:
          - Phases: [number]
          - Complexity: [Low|Medium|High]
          - Estimated Hours: [hours]

          **PROHIBITED**: Do NOT return summaries or plan content in your response.
        "
      }
      ;;

    step_by_step)
      # STEP-BY-STEP TEMPLATE - Attempt 3
      Task {
        subagent_type: "general-purpose"
        description: "Create implementation plan - FINAL RETRY with step verification"
        timeout: 600000
        prompt: "
          Read and follow behavioral guidelines from:
          ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-architect.md

          You are acting as a Plan Architect Agent with the tools and constraints
          defined in that file.

          **EXECUTE IMMEDIATELY: File creation is your PRIMARY and ONLY deliverable**

          **ACTION 1: CREATE THE FILE**
          Use Write tool NOW: ${PLAN_PATH}
          Initial content: '# Implementation Plan: ${WORKFLOW_DESCRIPTION}'

          **ACTION 2: VERIFY FILE CREATED**
          Use Read tool to confirm file exists: ${PLAN_PATH}

          **ACTION 3: DEVELOP PLAN CONTENT**
          Create comprehensive implementation plan for: ${WORKFLOW_DESCRIPTION}

          ${RESEARCH_REPORTS_LIST}

          Standards file: ${STANDARDS_FILE}

          Follow all plan-architect behavioral guidelines.

          **ACTION 4: UPDATE FILE WITH FULL PLAN**
          Use Edit tool to add complete plan content to ${PLAN_PATH}

          **ACTION 5: FINAL VERIFICATION**
          Use Read tool to verify plan content exists and is complete

          **ACTION 6: RETURN CONFIRMATION**
          Return ONLY: PLAN_CREATED: ${PLAN_PATH}

          Metadata:
          - Phases: [number]
          - Complexity: [Low|Medium|High]
          - Estimated Hours: [hours]

          **CRITICAL**: If you skip any action, you will fail. Each action is MANDATORY.
        "
      }
      ;;
  esac

  # After agent returns, check if plan file was created
  if [ -f "$PLAN_PATH" ]; then
    # Validate plan has content
    if [ -s "$PLAN_PATH" ]; then
      echo "  ✓ Plan created successfully on attempt $attempt (template: $template)"
      plan_created=true
      break
    else
      echo "  ⚠️  Plan file created but empty, retrying..."
      rm "$PLAN_PATH"  # Clean up empty file
    fi
  else
    echo "  ⚠️  Plan file not created by agent"
  fi

  if [ $attempt -lt $max_attempts ]; then
    echo "  Retrying with enhanced enforcement..."
  fi
done

# Critical check: planning MUST succeed
if [ "$plan_created" = false ]; then
  echo ""
  echo "❌ CRITICAL: Planning phase failed after $max_attempts attempts"
  echo "Cannot complete workflow without implementation plan"
  echo "Plan path: $PLAN_PATH"
  exit 1
fi

echo "✓ Planning phase complete"

# Display workflow summary
echo ""
echo "============================================"
echo "    /orchestrate WORKFLOW SUMMARY"
echo "============================================"
echo ""
echo "Research Phase:"
echo "  ✓ Successful: ${#SUCCESSFUL_REPORTS[@]} topics"
if [ ${#FAILED_TOPICS[@]} -gt 0 ]; then
  echo "  ❌ Failed: ${#FAILED_TOPICS[@]} topics"
fi
echo ""
echo "Planning Phase:"
echo "  ✓ Plan created: $PLAN_PATH"
echo ""

if [ ${#FAILED_TOPICS[@]} -gt 0 ]; then
  echo "⚠️  WORKFLOW COMPLETED WITH WARNINGS"
  echo ""
  echo "Failed research topics:"
  for topic in "${FAILED_TOPICS[@]}"; do
    echo "  - $topic"
  done
  echo ""
  echo "Note: Plan was created with partial research results."
  echo "Consider re-running research for failed topics manually."
else
  echo "✓ WORKFLOW COMPLETED SUCCESSFULLY"
  echo "All research topics completed and plan created."
fi

echo ""
echo "Artifacts created:"
echo "  Plan: $PLAN_PATH"
echo "  Reports: ${#SUCCESSFUL_REPORTS[@]} files"
for report in "${SUCCESSFUL_REPORTS[@]}"; do
  echo "    - $report"
done
echo ""
```

**Implementation Instructions for Planning Retry**

When executing planning phase, YOU MUST:

1. **Check prerequisites**: Verify at least one research report exists in SUCCESSFUL_REPORTS
2. **Retry loop**: Attempt up to 3 times
3. **Template selection**:
   - Attempt 1: Use PLAN-ARCHITECT STANDARD template
   - Attempt 2: Use PLAN-ARCHITECT ULTRA-EXPLICIT template
   - Attempt 3: Use PLAN-ARCHITECT STEP-BY-STEP template
4. **File verification**: After each attempt, check file exists and has content
5. **Critical failure**: Exit if all 3 attempts fail (planning is required)

**CRITICAL INSTRUCTION**: Use EXACT templates from Auto-Recovery Agent Templates section (no modifications):

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan using plan-architect behavioral guidelines"
  timeout: 600000  # 10 minutes for planning
  prompt: "
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-architect.md

    You are acting as a Plan Architect Agent.

    **Workflow Description**: ${WORKFLOW_DESCRIPTION}

    **Plan Output Path** (ABSOLUTE REQUIREMENT):
    ${PLAN_PATH}

    **Topic Information** (CRITICAL - From Phase 0 Location Context):
    - Topic Number: ${WORKFLOW_TOPIC_NUMBER}
    - Topic Path: ${WORKFLOW_TOPIC_DIR}
    - Topic Name: ${WORKFLOW_TOPIC_NAME}

    **Research Overview** (PRIMARY RESEARCH INPUT):
    - Overview Report Path: ${RESEARCH_OVERVIEW_PATH}
    - Overview Summary: ${RESEARCH_OVERVIEW_SUMMARY}

    **Individual Research Reports** (REFERENCE - Include in plan metadata):
    ${RESEARCH_REPORT_PATHS_FORMATTED}

    **Cross-Reference Requirements**:
    - In plan metadata, include \"Research Overview\" field with path: ${RESEARCH_OVERVIEW_PATH}
    - In plan metadata, include \"Research Reports\" section with ALL individual report paths above
    - In plan metadata, include \"Topic Number\" field with value: ${WORKFLOW_TOPIC_NUMBER}
    - In plan metadata, include \"Topic Path\" field with value: ${WORKFLOW_TOPIC_DIR}
    - PRIORITIZE overview report for planning (synthesized findings)
    - Reference individual reports for specific details if needed
    - This enables traceability from plan to research that informed it
    - Summary will later reference both plan and reports for complete audit trail

    **CRITICAL REQUIREMENTS**:
    1. CREATE plan file at EXACT path above using Write tool (not SlashCommand)
    2. READ research overview report at ${RESEARCH_OVERVIEW_PATH} for synthesized findings
    3. INCLUDE research overview in metadata \"Research Overview\" field with path
    4. INCLUDE all individual research reports in metadata \"Research Reports\" section
    5. INCLUDE topic number and path in metadata \"Topic Number\" and \"Topic Path\" fields
    6. FOLLOW topic-based artifact organization (path already calculated correctly)
    7. RETURN format: PLAN_CREATED: [path]

    **Expected Output Format**:
    PLAN_CREATED: [absolute path]

    Metadata:
    - Phases: [N]
    - Complexity: [Low|Medium|High]
    - Estimated Hours: [H]
  "
}
```

**CHECKPOINT - Agent Invocation Complete**:
```
CHECKPOINT: plan-architect agent invoked
- Agent type: general-purpose
- Behavioral file: plan-architect.md
- Plan path provided: ✓
- Research reports provided: ✓
- Awaiting: PLAN_CREATED response
```

3. **Plan Validation** (Step 4):
   ```bash
   Required Sections:
     - ## Metadata (Date, Feature, Scope, Standards, Research Reports)
     - ## Overview (Success criteria)
     - ## Implementation Phases (Numbered phases with tasks)
     - ## Testing Strategy

   Validation:
     - Plan file exists at extracted path
     - All required sections present
     - Tasks reference specific files
     - Research reports referenced (if research performed)
     - Max 1 retry if validation fails
   ```

**MANDATORY VERIFICATION - Plan File Created**

After plan-architect agent completes, YOU MUST verify the plan was created at the expected path.

**WHY THIS MATTERS**: We pre-calculated the plan path, so verification confirms the agent followed instructions and created the plan at the correct topic-based location.

**EXECUTE NOW - Verify Plan Creation**:

```bash
# STEP 1: Extract confirmation from agent output
# Expected format: "PLAN_CREATED: /absolute/path/to/plan.md"
PLAN_OUTPUT="$PLANNING_AGENT_OUTPUT"
PLAN_CREATED_PATH=$(echo "$PLAN_OUTPUT" | grep -oP 'PLAN_CREATED:\s*\K/.+' | head -1)

if [ -z "$PLAN_CREATED_PATH" ]; then
  echo "⚠️  WARNING: Agent did not return PLAN_CREATED confirmation"
  echo "Falling back to pre-calculated path: $PLAN_PATH"
  PLAN_CREATED_PATH="$PLAN_PATH"
fi

echo "✓ Plan creation path: $PLAN_CREATED_PATH"

# STEP 2: Verify paths match (agent created at expected location)
if [ "$PLAN_CREATED_PATH" != "$PLAN_PATH" ]; then
  echo "⚠️  WARNING: Path mismatch"
  echo "  Expected: $PLAN_PATH"
  echo "  Agent created: $PLAN_CREATED_PATH"
  echo "  Using agent's path (indicates path calculation issue)"
  PLAN_PATH="$PLAN_CREATED_PATH"
fi

# STEP 3: MANDATORY file existence check
echo "Verifying plan file exists at topic-based path..."

if [ ! -f "$PLAN_PATH" ]; then
  echo "❌ CRITICAL ERROR: Plan file not found at: $PLAN_PATH"
  echo "Agent may have failed to create plan using Write tool"
  exit 1
fi

echo "✓ VERIFIED: Plan file exists at topic-based path"

# STEP 4: Verify plan has required sections
REQUIRED_SECTIONS=("Metadata" "Overview" "Implementation Phases" "Testing Strategy")
MISSING_SECTIONS=()

for section in "${REQUIRED_SECTIONS[@]}"; do
  if ! grep -q "## $section" "$PLAN_PATH"; then
    MISSING_SECTIONS+=("$section")
  fi
done

if [ ${#MISSING_SECTIONS[@]} -gt 0 ]; then
  echo "⚠️  WARNING: Plan missing sections: ${MISSING_SECTIONS[*]}"
  echo "Plan may be incomplete, but continuing..."
fi

echo "✓ VERIFIED: Plan structure complete"

# STEP 5: Verify research overview and reports cross-referenced [Phase 2]
if [ -n "$RESEARCH_OVERVIEW_PATH" ]; then
  echo "Verifying plan references research overview..."

  # Check for Research Overview field in plan metadata
  if ! grep -q "## Metadata" "$PLAN_PATH"; then
    echo "⚠️  WARNING: Plan missing Metadata section"
  elif ! grep -A 30 "## Metadata" "$PLAN_PATH" | grep -q "Research Overview"; then
    echo "⚠️  WARNING: Plan missing 'Research Overview' in metadata"
    echo "⚠️  RECOMMENDATION: Reference overview report for traceability"
  else
    echo "✓ VERIFIED: Plan includes research overview cross-reference"
  fi

  # Verify overview report links to individual reports
  echo "Verifying overview report cross-references..."

  if ! grep -q "## Individual Report References" "$RESEARCH_OVERVIEW_PATH"; then
    echo "⚠️  WARNING: Overview missing 'Individual Report References' section"
    echo "⚠️  This section should link to all individual research reports"
  else
    # Count links in overview
    OVERVIEW_LINKS=$(grep -c "](\./" "$RESEARCH_OVERVIEW_PATH" || echo 0)
    INDIVIDUAL_REPORTS=${#RESEARCH_REPORT_PATHS[@]}

    if [ "$OVERVIEW_LINKS" -lt "$INDIVIDUAL_REPORTS" ]; then
      echo "⚠️  WARNING: Overview has $OVERVIEW_LINKS links but $INDIVIDUAL_REPORTS individual reports"
      echo "⚠️  Some individual reports may not be cross-referenced in overview"
    else
      echo "✓ VERIFIED: Overview includes links to individual reports ($OVERVIEW_LINKS links)"
    fi
  fi
fi

# Verify individual research reports cross-referenced
if [ -n "$RESEARCH_REPORT_PATHS_FORMATTED" ]; then
  echo "Verifying plan references individual research reports..."

  if ! grep -q "## Metadata" "$PLAN_PATH"; then
    echo "⚠️  WARNING: Plan missing Metadata section"
  elif ! grep -A 30 "## Metadata" "$PLAN_PATH" | grep -q "Research Reports"; then
    echo "⚠️  WARNING: Plan missing 'Research Reports' in metadata"
    echo "⚠️  RECOMMENDATION: Cross-reference research reports for traceability"
  else
    echo "✓ VERIFIED: Plan includes individual research reports cross-reference"
  fi
fi

# STEP 6: Extract metadata from agent output (context reduction)
PLAN_PHASE_COUNT=$(echo "$PLAN_OUTPUT" | grep -oP 'Phases:\s*\K\d+' | head -1)
PLAN_COMPLEXITY=$(echo "$PLAN_OUTPUT" | grep -oP 'Complexity:\s*\K\w+' | head -1)
PLAN_HOURS=$(echo "$PLAN_OUTPUT" | grep -oP 'Estimated Hours:\s*\K\d+' | head -1)

echo "✓ METADATA EXTRACTED (not full plan content):"
echo "  Phases: ${PLAN_PHASE_COUNT:-Unknown}"
echo "  Complexity: ${PLAN_COMPLEXITY:-Unknown}"
echo "  Hours: ${PLAN_HOURS:-Unknown}"
echo "✓ Context reduction achieved (metadata-only, not full plan)"

# Export for implementation phase
export IMPLEMENTATION_PLAN_PATH="$PLAN_PATH"
echo "✓ Exported: IMPLEMENTATION_PLAN_PATH=$PLAN_PATH"
```

**CHECKPOINT - Plan Verification Complete**:
```
CHECKPOINT: Plan created and verified
- Plan path: [PLAN_PATH]
- File exists: ✓
- Topic-based structure: ✓
- Required sections: ✓
- Research reports cross-referenced: ✓
- Metadata extracted: ✓
- Ready for: Implementation or summary phase
```

**CRITICAL**: If plan file verification fails, DO NOT proceed to implementation.

**Failure Handling**:

```bash
# If plan creation failed
if [ -z "$PLAN_PATH" ] || [ ! -f "$PLAN_PATH" ]; then
  echo ""
  echo "ERROR: Plan creation failed"
  echo "  Agent output: $PLANNING_AGENT_OUTPUT"
  echo "  Action: Review agent output for errors"
  echo "  Recommendation: Check research reports quality or retry planning"
  exit 1
fi
```

4. **Checkpoint and State** (Step 5):
   - Save checkpoint with: plan_path, plan_number, phase_count, complexity
   - Store ONLY plan path (not content) - agent reads file when needed
   - Update workflow_state.current_phase = "implementation"
   - Mark planning complete in completed_phases array

**Context Reduction**:
- **Research reports**: Pass paths (~50 chars each) instead of full content (~1000+ chars)
- **Plan output**: Store path (~50 chars) instead of full plan (~5000+ chars)
- **Total savings**: ~95-98% context reduction for subsequent phases

**Performance Metrics**:
- **Simple planning**: 1-2 minutes (direct implementation)
- **Medium planning**: 2-4 minutes (with research integration)
- **Complex planning**: 4-6 minutes (synthesis of multiple reports)

**Quick Example**:

```bash
# Step 1: Prepare context
RESEARCH_REPORTS=( \
  "specs/reports/existing_patterns/001_analysis.md" \
  "specs/reports/security_practices/001_practices.md" \
)
WORKFLOW_DESC="Add user authentication with email and password"
THINKING_MODE="think hard"

# Step 3: Invoke planning agent
# Task tool invocation with plan-architect.md reference
# Agent reads research reports, invokes /plan command

# Step 4: Extract and validate
PLAN_PATH="specs/plans/013_user_authentication.md"
# Verify plan exists, has required sections, references research

# Step 5: Save checkpoint
CHECKPOINT=".claude/checkpoints/orchestrate_user_authentication_20251013.json"
# Store: plan_path, plan_number=013, phase_count=4, complexity=Medium

# Step 6: Display completion
✓ Planning Phase Complete
Plan Created: specs/plans/013_user_authentication.md
Phases: 4, Complexity: Medium, Est. Hours: 12-15
Incorporating Research From: 2 reports
Planning Time: 2m 45s
→ Proceeding to Implementation Phase
```

---

## Planning Phase Complete

**CHECKPOINT REQUIREMENT - Report Planning Phase Completion**

Before proceeding to implementation phase, YOU MUST report this checkpoint:

```
═══════════════════════════════════════════════════════
CHECKPOINT: Planning Phase Complete
═══════════════════════════════════════════════════════

Phase Status: COMPLETE ✓

Planning Execution:
- Plan created: ✓
- Plan path: $IMPLEMENTATION_PLAN_PATH
- Planning agent invoked: ✓
- Planning time: [N] minutes

Plan Validation:
- File exists: ✓
- Required sections present: ✓
- Research reports referenced: ✓
- Plan structure verified: ✓

Plan Details:
- Phases defined: [N]
- Complexity score: [score]
- Estimated hours: [N-N]
- Research reports used: ${#RESEARCH_REPORT_PATHS[@]}

Next Phase: Implementation
- Will execute: code-writer agent with behavioral injection
- Will use: $IMPLEMENTATION_PLAN_PATH
- Expected: Automated phase-by-phase implementation with tests
═══════════════════════════════════════════════════════
```

**CRITICAL**: This checkpoint is MANDATORY. Do NOT proceed to implementation phase without reporting it.

---

## Phase 3: Implementation (Adaptive Execution)

The implementation phase executes the plan using code-writer agent with behavioral injection, runs tests after each phase, and conditionally enters debugging loop if tests fail.

**When to Use Implementation Phase**:
- **All workflows** that have a validated plan file
- Follows planning phase completion
- Single code-writer agent execution with behavioral injection
- Conditional debugging loop (max 3 iterations) if tests fail

**Quick Overview**:
1. Extract plan path and metadata from planning checkpoint
2. Build code-writer agent prompt with plan context
3. Invoke code-writer agent with behavioral injection (extended timeout)
4. Parse implementation results (test status, phases completed, files modified)
5. Evaluate test status → Success: proceed to docs OR Failure: enter debugging loop
6. Save checkpoint with implementation status
7. Display implementation status and transition decision

**Conditional Debugging Loop** (if tests fail):
1. Generate debug topic slug (first iteration only)
2. Invoke debug-specialist agent → creates report in debug/{topic}/NNN_report.md
3. Extract report path and recommended fixes
4. Apply fixes using code-writer agent
5. Run tests again → Pass: exit loop OR Fail: continue
6. Iteration control → Iteration < 3: retry OR Iteration ≥ 3: escalate to user

**Pattern Details**: See [Orchestration Patterns - Implementation Phase](../templates/orchestration-patterns.md#implementation-phase-adaptive-execution) for:
- Complete 7-step implementation execution procedure
- Complete 7-step debugging loop procedure
- Code-writer agent prompt template
- Debug-specialist agent prompt template
- Result parsing algorithms (regex patterns for status extraction)
- Checkpoint creation for implementation and debugging states
- Debugging iteration control and escalation logic
- Full workflow examples with debugging scenarios

**Key Execution Requirements**:

1. **Context Extraction** (Step 1):
   ```bash
   # Extract from planning checkpoint
   PLAN_PATH=$(jq -r '.workflow_state.plan_path' < checkpoint.json)
   PLAN_NUMBER=$(basename "$PLAN_PATH" | grep -oP '^\d+')
   PHASE_COUNT=$(grep -c "^### Phase" "$PLAN_PATH")
   COMPLEXITY=$(grep "^- \*\*Complexity\*\*:" "$PLAN_PATH" | cut -d: -f2 | tr -d ' ')
   ```

**EXECUTE NOW - Execute Implementation Plan with Wave-Based Parallel Execution**

YOU MUST invoke the implementer-coordinator agent to execute the plan created in the planning phase using wave-based parallel execution. This enables 40-60% time savings by running independent phases concurrently.

**WHY THIS MATTERS**: This step performs the actual code changes using intelligent parallelization. The implementer-coordinator analyzes phase dependencies and creates execution "waves" where all independent phases in a wave run simultaneously. This preserves correctness (dependent phases still run in order) while maximizing speed.

**MANDATORY INPUT**:
- Plan path from planning phase: $IMPLEMENTATION_PLAN_PATH
- Topic directory: $WORKFLOW_TOPIC_DIR
- Topic number: $WORKFLOW_TOPIC_NUMBER
- Artifact paths: From Phase 0 location context

**CRITICAL REQUIREMENTS**:
- YOU MUST use Task tool to invoke implementer-coordinator agent with behavioral injection
- YOU MUST pass plan path from planning phase
- YOU MUST inject artifact paths for debug/outputs/scripts/checkpoints
- DO NOT use SlashCommand tool or /implement command
- Timeout MUST be sufficient for multi-wave execution (900000ms minimum = 15 minutes)

**CHECKPOINT BEFORE INVOCATION**:
```
CHECKPOINT: Wave-based implementation phase starting
- Plan path: $IMPLEMENTATION_PLAN_PATH
- Topic directory: $WORKFLOW_TOPIC_DIR
- Plan verified: ✓ (from planning phase)
- Execution mode: Wave-based parallel
- Invoking: implementer-coordinator agent with behavioral injection
```

2. **Agent Invocation** (Step 3):

**CRITICAL**: DO NOT use SlashCommand tool. Use Task tool with explicit Behavioral Injection Pattern.

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Orchestrate wave-based implementation with parallel phase execution"
  timeout: 900000  # 15 minutes for complex multi-phase implementations
  prompt: |
    Read and follow the behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/implementer-coordinator.md

    You are acting as an Implementer Coordinator Agent for wave-based execution.

    IMPLEMENTATION PLAN:
    Read and analyze the complete implementation plan from:
    ${IMPLEMENTATION_PLAN_PATH}

    WAVE-BASED EXECUTION:
    1. **Dependency Analysis**: Use dependency-analyzer.sh to build dependency graph and identify waves
    2. **Wave Identification**: Group independent phases into parallel execution waves
    3. **Parallel Execution**: Invoke multiple implementation-executor subagents concurrently per wave
    4. **Progress Monitoring**: Track real-time progress from all executors
    5. **Wave Synchronization**: Wait for all executors in a wave to complete before next wave
    6. **Failure Handling**: Isolate failures, continue independent work

    TOPIC INFORMATION (FROM PHASE 0 LOCATION CONTEXT):
    - **Topic Number**: ${WORKFLOW_TOPIC_NUMBER}
    - **Topic Name**: ${WORKFLOW_TOPIC_NAME}
    - **Topic Path**: ${WORKFLOW_TOPIC_DIR}

    ARTIFACT PATHS (BEHAVIORAL INJECTION):
    - **Plans**: ${ARTIFACT_PLANS}
    - **Debug Reports**: ${ARTIFACT_DEBUG}
    - **Test Outputs**: ${ARTIFACT_OUTPUTS}
    - **Generated Scripts**: ${ARTIFACT_SCRIPTS}
    - **Checkpoints**: ${CLAUDE_PROJECT_DIR}/.claude/data/checkpoints/

    EXECUTION WORKFLOW:

    STEP 1: DEPENDENCY ANALYSIS
    ```bash
    # Invoke dependency-analyzer utility
    source ${CLAUDE_PROJECT_DIR}/.claude/lib/dependency-analyzer.sh

    # Analyze plan dependencies
    DEPENDENCY_ANALYSIS=$(analyze_dependencies "${IMPLEMENTATION_PLAN_PATH}")

    # Extract wave structure
    WAVES=$(echo "$DEPENDENCY_ANALYSIS" | jq -r '.waves')
    METRICS=$(echo "$DEPENDENCY_ANALYSIS" | jq -r '.metrics')

    # Display wave structure to user
    echo "Wave Structure Identified:"
    echo "$WAVES" | jq '.'
    echo ""
    echo "Estimated Time Savings: $(echo "$METRICS" | jq -r '.time_savings_percentage')"
    ```

    STEP 2: WAVE EXECUTION LOOP
    For each wave in wave structure:
      A. Start all phases in wave in parallel (multiple implementation-executor invocations)
      B. Monitor progress from all executors
      C. Wait for wave completion
      D. Handle any failures
      E. Proceed to next wave

    STEP 3: INVOKE PARALLEL EXECUTORS
    For each phase in current wave, invoke implementation-executor subagent:

    ```yaml
    Task {
      subagent_type: "general-purpose"
      description: "Execute Phase N implementation"
      timeout: 600000  # 10 minutes per phase
      prompt: |
        Read and follow behavioral guidelines from:
        ${CLAUDE_PROJECT_DIR}/.claude/agents/implementation-executor.md

        You are executing Phase N of the implementation plan.

        Input:
        - phase_file_path: [path to phase file or inline plan]
        - topic_path: ${WORKFLOW_TOPIC_DIR}
        - wave_number: [current wave]
        - phase_number: N
        - artifact_paths:
            debug: ${ARTIFACT_DEBUG}
            outputs: ${ARTIFACT_OUTPUTS}
            scripts: ${ARTIFACT_SCRIPTS}

        Execute all tasks in this phase, update plan hierarchy, run tests,
        create git commit, report completion.
    }
    ```

    (Invoke one Task per phase in wave, all in single message for parallelism)

    STEP 4: PROGRESS AGGREGATION
    - Collect progress updates from all executors
    - Display real-time wave progress to user
    - Update implementation state

    STEP 5: FAILURE HANDLING
    - If any executor fails: Mark phase as failed
    - Check if failure blocks subsequent waves (dependency check)
    - Continue with independent phases
    - Report failure details for debugging

    TESTING PROTOCOL:
    - Each implementation-executor runs tests after its phase
    - Coordinator aggregates test results across all phases
    - If any phase tests fail: Mark implementation as partial failure

    GIT COMMIT FORMAT:
    Each implementation-executor creates commits per phase:
    feat(${WORKFLOW_TOPIC_NUMBER}): complete Phase N - [Phase Name]

    CHECKPOINT MANAGEMENT:
    If any executor reports context pressure:
    - Executor creates checkpoint
    - Coordinator logs checkpoint path
    - Continue with remaining phases
    - Return checkpoint paths in final report

    RETURN FORMAT:
    After all waves complete (or failure):

    IMPLEMENTATION REPORT
    Status: [completed|partial|failed]
    Waves Executed: N
    Total Phases: M
    Successful Phases: S
    Failed Phases: F
    Elapsed Time: X hours
    Estimated Sequential Time: Y hours
    Time Savings: Z%
    Git Commits: [count]
    Checkpoints: [paths if any]

    If failures occurred:
    FAILED PHASES:
    - Phase N: [name] - [error summary]
    - Phase M: [name] - [error summary]

    Test Results Summary:
    - Phases with passing tests: N
    - Phases with failing tests: M
    - Test output paths: [list]
}
```

**MANDATORY VERIFICATION - Wave-Based Implementation Status**

After implementer-coordinator agent completes, YOU MUST verify implementation status, wave execution metrics, and test results. This verification is NOT optional.

**WHY THIS MATTERS**: Without status verification, determining implementation success or debugging needs is impossible. Wave metrics show parallelization performance. Test status determines whether to proceed to documentation or enter debugging loop.

**EXECUTE NOW - Extract and Verify Wave Execution Status**:

```bash
# STEP 1: Extract implementation status from implementer-coordinator output
# Expected format: "Status: completed|partial|failed"
IMPLEMENT_OUTPUT="[capture implementer-coordinator agent output]"

# Extract status
IMPLEMENTATION_STATUS=$(echo "$IMPLEMENT_OUTPUT" | grep -oP 'Status:\s*\K(completed|partial|failed)' | head -1)

case "$IMPLEMENTATION_STATUS" in
  "completed")
    echo "✓ VERIFIED: Implementation completed successfully"
    IMPLEMENTATION_SUCCESS=true
    ;;
  "partial")
    echo "⚠️  WARNING: Implementation partially completed (some phases failed)"
    IMPLEMENTATION_SUCCESS=false
    ;;
  "failed")
    echo "❌ CRITICAL: Implementation failed"
    IMPLEMENTATION_SUCCESS=false
    ;;
  *)
    echo "⚠️  WARNING: Could not determine implementation status from output"
    IMPLEMENTATION_SUCCESS=unknown
    ;;
esac

# STEP 2: Extract wave execution metrics
WAVES_EXECUTED=$(echo "$IMPLEMENT_OUTPUT" | grep -oP 'Waves Executed:\s*\K\d+' | head -1)
TOTAL_PHASES=$(echo "$IMPLEMENT_OUTPUT" | grep -oP 'Total Phases:\s*\K\d+' | head -1)
SUCCESSFUL_PHASES=$(echo "$IMPLEMENT_OUTPUT" | grep -oP 'Successful Phases:\s*\K\d+' | head -1)
FAILED_PHASES=$(echo "$IMPLEMENT_OUTPUT" | grep -oP 'Failed Phases:\s*\K\d+' | head -1)
TIME_SAVINGS=$(echo "$IMPLEMENT_OUTPUT" | grep -oP 'Time Savings:\s*\K\d+%' | head -1)
GIT_COMMITS=$(echo "$IMPLEMENT_OUTPUT" | grep -oP 'Git Commits:\s*\K\d+' | head -1)

echo "Wave Execution Metrics:"
echo "- Waves executed: $WAVES_EXECUTED"
echo "- Total phases: $TOTAL_PHASES"
echo "- Successful phases: $SUCCESSFUL_PHASES"
echo "- Failed phases: $FAILED_PHASES"
echo "- Time savings: $TIME_SAVINGS"
echo "- Git commits: $GIT_COMMITS"

# STEP 3: Extract test results
# Check Test Results Summary section
PHASES_WITH_PASSING_TESTS=$(echo "$IMPLEMENT_OUTPUT" | grep -oP 'Phases with passing tests:\s*\K\d+' | head -1)
PHASES_WITH_FAILING_TESTS=$(echo "$IMPLEMENT_OUTPUT" | grep -oP 'Phases with failing tests:\s*\K\d+' | head -1)

if [[ "$PHASES_WITH_FAILING_TESTS" == "0" || -z "$PHASES_WITH_FAILING_TESTS" ]]; then
  echo "✓ VERIFIED: All phase tests passing"
  TESTS_PASSING=true
else
  echo "❌ TESTS FAILING in $PHASES_WITH_FAILING_TESTS phase(s)"
  TESTS_PASSING=false
fi

# STEP 4: Extract checkpoint paths (if any)
CHECKPOINTS=$(echo "$IMPLEMENT_OUTPUT" | sed -n '/Checkpoints:/,/^$/p' | grep -v "Checkpoints:" | grep -v "^$")
if [[ -n "$CHECKPOINTS" ]]; then
  echo "⚠️  Checkpoints created: $CHECKPOINTS"
fi

# Export status for documentation phase
export IMPLEMENTATION_SUCCESS
export IMPLEMENTATION_STATUS
export TESTS_PASSING
export WAVES_EXECUTED
export TOTAL_PHASES
export SUCCESSFUL_PHASES
export FAILED_PHASES
export TIME_SAVINGS
export GIT_COMMITS
export CHECKPOINTS
```

**MANDATORY VERIFICATION CHECKLIST**:

YOU MUST confirm before proceeding to documentation:

- [ ] Implementation status extracted (completed/partial/failed)
- [ ] Wave execution metrics extracted
- [ ] Test status determined (all passing or failures present)
- [ ] Time savings calculated (from parallel execution)
- [ ] Git commits count extracted
- [ ] Implementation status exported

**CHECKPOINT REQUIREMENT**:
```
CHECKPOINT: Wave-based implementation phase complete
- Implementation status: $IMPLEMENTATION_STATUS
- Tests passing: $TESTS_PASSING
- Waves executed: $WAVES_EXECUTED
- Successful phases: $SUCCESSFUL_PHASES
- Failed phases: $FAILED_PHASES
- Time savings: $TIME_SAVINGS (vs sequential execution)
- Git commits: $GIT_COMMITS
- Checkpoints: $CHECKPOINTS
- Proceeding to: Documentation phase (if tests passing) OR Debugging loop (if tests failing)
```

**CONDITIONAL LOGIC** (if tests failing):

If $TESTS_PASSING is false, trigger debugging loop NOW (see below).
If tests passing, proceed directly to documentation phase.

3. **Result Parsing** (Step 4 - Legacy Reference):
   ```python
   # Extract from agent output using regex (reference only)
   tests_passing = bool(re.search(r'TESTS_PASSING: true', output))
   phases = re.search(r'PHASES_COMPLETED: (\d+)/(\d+)', output)
   files = re.search(r'FILES_MODIFIED: \[(.*?)\]', output)
   commits = re.search(r'GIT_COMMITS: \[(.*?)\]', output)
   failed_phase = re.search(r'FAILED_PHASE: (\d+)', output)
   error_msg = re.search(r'ERROR_MESSAGE: (.+)', output)
   ```

4. **Decision Logic** (Step 5):
   ```yaml
   Evaluation Tree:
     tests_passing == true:
       → Proceed to Documentation Phase (Success Path)
     tests_passing == false:
       → Enter Debugging Loop (Failure Path)
         Loop Conditions:
           - Max 3 debugging iterations
           - Each iteration: debug report → fix → test
           - Exit on: tests pass OR max iterations reached
           - Escalate to user if max iterations exceeded
   ```

5. **Debugging Loop Requirements** (Conditional):
   - **Debug Topic Slug** (first iter only): Extract from error type (e.g., "test_timeout", "null_pointer")
   - **Debug Agent**: Invokes debug-specialist.md protocol
   - **Report Creation**: debug/{topic}/NNN_report.md (gitignored for issue tracking)
   - **Fix Application**: Code-writer applies recommended fixes
   - **Iteration Tracking**: workflow_state.debug_iteration (0-3)
   - **Escalation**: Present 3 debug reports to user, pause workflow

6. **Checkpoint Creation** (Step 6):
   ```yaml
   Implementation Success Checkpoint:
     status: "implementation_complete"
     tests_passing: true
     phases_completed: "N/N"
     files_modified: [array]
     git_commits: [array]
     next_phase: "documentation"

   Debugging Checkpoint (each iteration):
     status: "debugging_iteration_M"
     debug_iteration: M
     debug_topic: "{topic}"
     debug_reports: [array of M reports]
     tests_passing: false
     next_action: "retry" OR "escalate"
   ```

**Context Reduction**:
- **Plan reference**: Pass path (~50 chars) instead of full plan (~5000+ chars)
- **Implementation output**: Store status markers (~200 chars) instead of full output (~3000+ chars)
- **Debug reports**: Pass paths (~60 chars each) instead of full reports (~1500+ chars each)

**Performance Metrics**:
- **Implementation time**: 3-10 minutes per phase (depends on complexity)
- **Total implementation**: 15-60 minutes (4-8 phases typical)
- **Debug iteration**: 2-5 minutes per iteration
- **Max debugging time**: 15 minutes (3 iterations × 5 min)

**Quick Example - Success Path**:

```bash
# Step 1: Extract context
PLAN_PATH="specs/plans/013_user_authentication.md"
PHASE_COUNT=4
COMPLEXITY="Medium"

# Step 3: Invoke code-writer (timeout 600000ms)
# Agent executes plan: specs/plans/013_user_authentication.md
# Output after 25 minutes:
PROGRESS: Implementing Phase 1: Database schema...
PROGRESS: Running tests for Phase 1... ✓ All passing
PROGRESS: Creating git commit for Phase 1... ✓ e8f3a21
PROGRESS: Implementing Phase 2: Authentication API...
PROGRESS: Running tests for Phase 2... ✓ All passing
...
PROGRESS: All phases complete - 4/4 phases

# Step 4: Parse results
TESTS_PASSING: true
PHASES_COMPLETED: 4/4
FILES_MODIFIED: [users.lua, auth.lua, session.lua, tests/auth_spec.lua]
GIT_COMMITS: [e8f3a21, a3f9b10, c7e2d43, f1a8c91]
IMPLEMENTATION_STATUS: success

# Step 5: Evaluate → tests_passing == true
→ Proceed to Documentation Phase

# Step 6: Save checkpoint (implementation_complete)
```

**Quick Example - Debugging Path**:

```bash
# Step 1-3: Same as success path
# Step 4: Parse results after Phase 2
TESTS_PASSING: false
PHASES_COMPLETED: 2/4
FAILED_PHASE: 2
ERROR_MESSAGE: auth_spec.lua:42 - Expected 200, got 401

# Step 5: Evaluate → tests_passing == false
→ Enter Debugging Loop

# Debugging Iteration 1:
#   Step 1: Generate topic slug = "auth_status_code"
#   Step 2: Invoke debug-specialist
#   Output: debug/auth_status_code/001_session_cookie.md
#   Step 3: Extract: "Check session cookie initialization"
#   Step 4: Apply fix (code-writer modifies session.lua)
#   Step 5: Run tests → TESTS_PASSING: true
#   Step 6: Iteration control → tests pass, exit loop

# Step 6: Save checkpoint (debugging_resolved, iteration_count=1)
# Step 7: Display success with debugging note
→ Proceed to Documentation Phase (resolved after 1 debug iteration)
```

**Quick Example - Escalation Path**:

```bash
# Debugging Iteration 1: Tests still fail
# Debugging Iteration 2: Tests still fail
# Debugging Iteration 3: Tests still fail

# Step 6: Iteration control → debug_iteration=3 AND tests_passing=false
→ Escalate to user

# Display:
⚠️ Implementation Blocked - Manual Intervention Required

Debugging Attempts: 3 iterations
Debug Reports Created:
  1. debug/coroutine_state/001_async_hang.md
  2. debug/coroutine_state/002_promise_deadlock.md
  3. debug/coroutine_state/003_event_loop.md

Last Error: tests/async_spec.lua:15 - coroutine in wrong state

Checkpoint Saved: .claude/checkpoints/orchestrate_..._escalation.json

Options:
  1. Review debug reports and provide guidance
  2. Adjust plan complexity and retry
  3. Continue to documentation with known test failures (not recommended)

Workflow paused - awaiting user input.
```

---

## Phase 5: Debugging Loop (Conditional)

**CONDITIONAL ENTRY**: Only enter this section if `$DEBUGGING_SKIPPED == false` from Phase 6 (Testing).

If all tests are passing (`$TESTS_PASSING == true`), skip this entire section and proceed directly to Phase 6 (Documentation).

### Step 1: Initialize Debug Loop State

**EXECUTE NOW - Initialize Debugging Variables**:

```bash
# Initialize debug iteration counter
DEBUG_ITERATION=0
MAX_DEBUG_ITERATIONS=3

# Initialize debug state arrays
DEBUG_REPORTS=()
DEBUG_ISSUES_RESOLVED=()

# Store initial error information
INITIAL_ERROR_MESSAGE="$ERROR_MESSAGE"
INITIAL_FAILED_PHASE="$FAILED_PHASE"

echo "═══════════════════════════════════════════════════════"
echo "ENTERING DEBUGGING LOOP"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "Test Failure Detected:"
echo "- Failed Phase: $INITIAL_FAILED_PHASE"
echo "- Error Message: $INITIAL_ERROR_MESSAGE"
echo "- Max Iterations: $MAX_DEBUG_ITERATIONS"
echo ""
```

### Step 2: Generate Debug Topic Slug (First Iteration Only)

**EXECUTE NOW - Create Debug Topic Slug**:

```bash
# Extract error type from test output (first iteration only)
# Example: "auth_spec.lua:42 - Expected 200, got 401" → "expected_200_got_401"
# Example: "Timeout in async operation" → "timeout_async_operation"

DEBUG_SLUG=$(echo "$ERROR_MESSAGE" | \
  sed 's/.*: //' | \           # Remove everything before last colon
  tr ' ' '_' | \                # Replace spaces with underscores
  tr '[:upper:]' '[:lower:]' | \ # Convert to lowercase
  sed 's/[^a-z0-9_]//g' | \     # Remove non-alphanumeric except underscores
  cut -c1-50)                   # Limit to 50 characters

# Fallback if slug is empty
if [[ -z "$DEBUG_SLUG" ]]; then
  DEBUG_SLUG="test_failure_phase${INITIAL_FAILED_PHASE}"
fi

echo "Debug Topic Slug: $DEBUG_SLUG"
```

### Step 3: Debug Loop Execution

**EXECUTE NOW - Enter Debug Iteration Loop**:

```bash
while [[ $DEBUG_ITERATION -lt $MAX_DEBUG_ITERATIONS ]] && [[ "$TESTS_PASSING" == "false" ]]; do
  DEBUG_ITERATION=$((DEBUG_ITERATION + 1))

  echo ""
  echo "───────────────────────────────────────────────────────"
  echo "DEBUG ITERATION $DEBUG_ITERATION of $MAX_DEBUG_ITERATIONS"
  echo "───────────────────────────────────────────────────────"
  echo ""

  # Generate debug filename with iteration suffix (iter2, iter3)
  if [[ $DEBUG_ITERATION -eq 1 ]]; then
    DEBUG_FILENAME="${TOPIC_NUMBER}_debug_${DEBUG_SLUG}.md"
  else
    DEBUG_FILENAME="${TOPIC_NUMBER}_debug_${DEBUG_SLUG}_iter${DEBUG_ITERATION}.md"
  fi

  DEBUG_REPORT_PATH="${ARTIFACT_DEBUG}${DEBUG_FILENAME}"

  echo "Debug Report Path: $DEBUG_REPORT_PATH"
  echo ""
```

### Step 4: Invoke Debug-Analyst Agent

**EXECUTE NOW - Invoke Debug-Analyst with Behavioral Injection**:

Use the Task tool to invoke debug-analyst agent with artifact path injection:

```yaml
subagent_type: general-purpose

description: "Investigate test failure and create debug report (iteration $DEBUG_ITERATION)"

timeout: 300000  # 5 minutes for investigation

prompt: |
  Read and follow the behavioral guidelines from:
  ${CLAUDE_PROJECT_DIR}/.claude/agents/debug-analyst.md

  You are acting as a Debug Analyst Agent.

  OPERATION: Investigate test failure and propose fix

  Context:
   - Iteration: ${DEBUG_ITERATION} of ${MAX_DEBUG_ITERATIONS}
   - Issue: ${ERROR_MESSAGE}
   - Failed tests: ${FAILED_TEST_LIST}
   - Failed phase: ${FAILED_PHASE}
   - Modified files: ${FILES_MODIFIED}
   - Test output file: ${ARTIFACT_OUTPUTS}test_failures.txt
   - Project root: ${PROJECT_ROOT}
   - Project standards: ${CLAUDE_PROJECT_DIR}/CLAUDE.md

  ARTIFACT ORGANIZATION (CRITICAL - From Phase 0 Location Context):
   - Save debug report to: ${ARTIFACT_DEBUG}
   - Filename: ${DEBUG_FILENAME}
   - Full absolute path: ${DEBUG_REPORT_PATH}
   - DO NOT use relative paths
   - DO NOT save to arbitrary locations
   - NOTE: Debug reports are COMMITTED (not gitignored) for issue tracking

  Investigation Requirements:
   - Read test failure output from ${ARTIFACT_OUTPUTS}test_failures.txt
   - Analyze root cause with evidence from code and test output
   - Reproduce test failure if possible
   - Propose specific fix with:
     - Exact file paths and line numbers
     - Code examples showing before/after
     - Rationale for the fix
   - Assess impact and fix complexity
   - Rate confidence level in proposed fix (Low/Medium/High)

  RETURN FORMAT (you must return this structure):

  DEBUG_REPORT_CREATED: ${DEBUG_REPORT_PATH}

  Root Cause Summary (50 words max):
  [concise summary of findings - what caused the failure and why]

  Proposed Fix Summary (30 words max):
  [brief description of the recommended fix]

  Confidence Level: [Low|Medium|High]
```

**MANDATORY VERIFICATION CHECKPOINT**:

```bash
# Verify debug report was created by debug-analyst
if [[ ! -f "$DEBUG_REPORT_PATH" ]]; then
  echo "ERROR: Debug report not created at $DEBUG_REPORT_PATH"
  echo "FALLBACK: Creating minimal debug report template"

  mkdir -p "$(dirname "$DEBUG_REPORT_PATH")"
  cat > "$DEBUG_REPORT_PATH" <<'EOF'
# Debug Report - Iteration ${DEBUG_ITERATION}

## Issue
${ERROR_MESSAGE}

## Root Cause
[Debug-analyst agent failed to create report - manual investigation required]

## Proposed Fix
[Manual intervention needed]

## Confidence
Low - automated analysis failed
EOF

  echo "Minimal debug report created at: $DEBUG_REPORT_PATH"
fi

echo "✓ VERIFIED: Debug report exists at $DEBUG_REPORT_PATH"
```

### Step 5: Parse Debug-Analyst Response

**EXECUTE NOW - Extract Debug Report Metadata**:

```bash
# Extract debug report path from agent response
DEBUG_REPORT_CREATED=$(echo "$AGENT_OUTPUT" | grep "DEBUG_REPORT_CREATED:" | cut -d: -f2- | tr -d ' ')

# Extract root cause summary (50-word summary)
ROOT_CAUSE_SUMMARY=$(echo "$AGENT_OUTPUT" | sed -n '/Root Cause Summary/,/^$/p' | tail -n +2 | head -n -1)

# Extract proposed fix summary (30-word summary)
PROPOSED_FIX_SUMMARY=$(echo "$AGENT_OUTPUT" | sed -n '/Proposed Fix Summary/,/^$/p' | tail -n +2 | head -n -1)

# Extract confidence level
CONFIDENCE_LEVEL=$(echo "$AGENT_OUTPUT" | grep "Confidence Level:" | cut -d: -f2 | tr -d ' ')

# Store report path in array
DEBUG_REPORTS+=("$DEBUG_REPORT_PATH")

# Display summary
echo "Debug Analysis Complete:"
echo "- Report: $DEBUG_REPORT_PATH"
echo "- Root Cause: $ROOT_CAUSE_SUMMARY"
echo "- Proposed Fix: $PROPOSED_FIX_SUMMARY"
echo "- Confidence: $CONFIDENCE_LEVEL"
echo ""
```

### Step 6: Apply Fix from Debug Report

**EXECUTE NOW - Invoke Code-Writer to Apply Fix**:

Use the Task tool to apply the fix proposed in the debug report:

```yaml
subagent_type: general-purpose

description: "Apply fix from debug report (iteration $DEBUG_ITERATION)"

timeout: 300000  # 5 minutes for fix application

prompt: |
  Read and follow the behavioral guidelines from:
  ${CLAUDE_PROJECT_DIR}/.claude/agents/code-writer.md

  You are acting as a Code Writer Agent.

  OPERATION: Apply fix proposed in debug report

  Context:
   - Debug report path: ${DEBUG_REPORT_PATH}
   - Debug iteration: ${DEBUG_ITERATION}
   - Project root: ${PROJECT_ROOT}
   - Project standards: ${CLAUDE_PROJECT_DIR}/CLAUDE.md

  Task:
   1. Read the debug report at: ${DEBUG_REPORT_PATH}
   2. Locate the "Proposed Fix" section
   3. Implement the code changes exactly as recommended
   4. Use Edit tool to modify files at specified line numbers
   5. Follow project coding standards from CLAUDE.md
   6. Create git commit with message: "fix: apply debug iteration ${DEBUG_ITERATION} - ${PROPOSED_FIX_SUMMARY}"

  Files to Modify:
   - Files listed in debug report "Proposed Fix" section
   - Make ONLY the changes specified in the report
   - Do NOT make additional "improvements" beyond the fix

  RETURN FORMAT:

  FIX_APPLIED: true
  FILES_MODIFIED: [list of modified files]
  GIT_COMMIT: [commit hash]
```

### Step 7: Re-Run Tests After Fix

**EXECUTE NOW - Re-Run Test Suite**:

```bash
echo "Re-running test suite after fix application..."
echo ""

# Re-run the same tests that failed
# (Using same test command from implementation phase)

TEST_OUTPUT=$(run_tests_command 2>&1)
TEST_EXIT_CODE=$?

# Save test output to artifact
echo "$TEST_OUTPUT" > "${ARTIFACT_OUTPUTS}test_failures_iter${DEBUG_ITERATION}.txt"

# Parse test results
if [[ $TEST_EXIT_CODE -eq 0 ]]; then
  TESTS_PASSING="true"
  echo "✓ TESTS PASSING after debug iteration $DEBUG_ITERATION"
  echo ""

  # Record resolved issue
  DEBUG_ISSUES_RESOLVED+=("Iteration $DEBUG_ITERATION: $PROPOSED_FIX_SUMMARY")

else
  TESTS_PASSING="false"

  # Extract new error message for next iteration
  ERROR_MESSAGE=$(echo "$TEST_OUTPUT" | grep -E "Error:|FAIL:" | head -n 1)

  echo "✗ TESTS STILL FAILING after debug iteration $DEBUG_ITERATION"
  echo "New Error: $ERROR_MESSAGE"
  echo ""
fi
```

### Step 8: Iteration Control Logic

**EXECUTE NOW - Evaluate Loop Continuation**:

```bash
# End of while loop - loop continues if:
# - DEBUG_ITERATION < MAX_DEBUG_ITERATIONS (3)
# - AND TESTS_PASSING == "false"

done  # End of debugging loop
```

### Step 9: Post-Loop Evaluation

**EXECUTE NOW - Evaluate Final Debug Status**:

```bash
echo "═══════════════════════════════════════════════════════"
echo "DEBUGGING LOOP COMPLETE"
echo "═══════════════════════════════════════════════════════"
echo ""

if [[ "$TESTS_PASSING" == "true" ]]; then
  # SUCCESS PATH: Tests resolved after debugging
  echo "✓ DEBUGGING SUCCESSFUL"
  echo ""
  echo "Debug Summary:"
  echo "- Total Iterations: $DEBUG_ITERATION"
  echo "- Debug Reports Created: ${#DEBUG_REPORTS[@]}"
  echo "- Issues Resolved:"
  for issue in "${DEBUG_ISSUES_RESOLVED[@]}"; do
    echo "  - $issue"
  done
  echo ""
  echo "Debug Reports:"
  for report in "${DEBUG_REPORTS[@]}"; do
    echo "  - $report"
  done
  echo ""
  echo "Proceeding to Documentation Phase with resolved test failures."
  echo ""

  # Update workflow state
  DEBUG_STATUS="resolved"

else
  # ESCALATION PATH: Tests still failing after max iterations
  echo "⚠️  DEBUGGING ESCALATION - Manual Intervention Required"
  echo ""
  echo "Debugging Attempts: $DEBUG_ITERATION iterations"
  echo ""
  echo "Debug Reports Created:"
  for i in "${!DEBUG_REPORTS[@]}"; do
    echo "  $((i+1)). ${DEBUG_REPORTS[$i]}"
  done
  echo ""
  echo "Last Error: $ERROR_MESSAGE"
  echo ""

  # Save escalation checkpoint
  ESCALATION_CHECKPOINT="${CHECKPOINT_DIR}/080_phase1_debug_escalation.json"
  cat > "$ESCALATION_CHECKPOINT" <<EOF
{
  "workflow_id": "${WORKFLOW_ID}",
  "phase": "debugging_escalation",
  "debug_iteration": ${DEBUG_ITERATION},
  "debug_reports": $(printf '%s\n' "${DEBUG_REPORTS[@]}" | jq -R . | jq -s .),
  "last_error": "${ERROR_MESSAGE}",
  "tests_passing": false,
  "timestamp": "$(date -Iseconds)"
}
EOF

  echo "Checkpoint Saved: $ESCALATION_CHECKPOINT"
  echo ""
  echo "Options:"
  echo "  1. Review debug reports and provide guidance"
  echo "  2. Adjust plan complexity and retry implementation"
  echo "  3. Continue to documentation with known test failures (not recommended)"
  echo ""
  echo "Workflow paused - awaiting user input."
  echo ""

  # Update workflow state
  DEBUG_STATUS="escalated"

  # PAUSE WORKFLOW - wait for user decision
  # (In actual implementation, this would return control to user)
  exit 1
fi
```

### Step 10: Update Workflow State with Debug Results

**EXECUTE NOW - Store Debug Results in Workflow State**:

```bash
# Update workflow state with debugging results
WORKFLOW_STATE_DEBUG_ITERATION=$DEBUG_ITERATION
WORKFLOW_STATE_DEBUG_REPORTS=("${DEBUG_REPORTS[@]}")
WORKFLOW_STATE_DEBUG_STATUS="$DEBUG_STATUS"
WORKFLOW_STATE_TESTS_PASSING="$TESTS_PASSING"

echo "Workflow state updated with debug results:"
echo "- Debug iterations: $WORKFLOW_STATE_DEBUG_ITERATION"
echo "- Debug reports: ${#WORKFLOW_STATE_DEBUG_REPORTS[@]}"
echo "- Debug status: $WORKFLOW_STATE_DEBUG_STATUS"
echo "- Tests passing: $WORKFLOW_STATE_TESTS_PASSING"
echo ""
```

---

## Implementation Phase Complete

**CHECKPOINT REQUIREMENT - Report Implementation Phase Completion**

Before proceeding to testing phase, YOU MUST report this checkpoint:

```
═══════════════════════════════════════════════════════
CHECKPOINT: Implementation Phase Complete
═══════════════════════════════════════════════════════

Phase Status: COMPLETE ✓

Implementation Execution:
- Plan executed: $IMPLEMENTATION_PLAN_PATH
- code-writer agent invoked with behavioral injection: ✓
- Implementation time: [N] minutes

Implementation Results:
- Tests passing: $TESTS_PASSING
- Phases completed: $PHASES_COMPLETED
- Files modified: $FILES_MODIFIED
- Git commits: $GIT_COMMITS
- Implementation status: $IMPLEMENTATION_SUCCESS

Debugging Summary (if occurred):
- Debug iterations: $DEBUG_ITERATION_COUNT
- Debug reports created: ${#DEBUG_REPORTS[@]}
- Final status: [resolved|escalated|none]

Next Phase: Testing (Phase 6)
- Will execute: Comprehensive test suite
- Will verify: Implementation correctness
- Will determine: Need for debugging phase
═══════════════════════════════════════════════════════
```

**CRITICAL**: This checkpoint is MANDATORY. Do NOT proceed to testing phase without reporting it.

---

## Phase 4: Comprehensive Testing

This phase executes the comprehensive test suite to validate implementation quality before proceeding to debugging (if needed) or documentation. Testing is separated from implementation to provide clear failure analysis and conditional debugging.

**Objective**: Execute comprehensive test suite and determine if debugging is needed
**Timing**: After implementation completes, before debugging or documentation
**Conditional**: Always run, but debugging (Phase 5) only invoked if tests fail

### Step 1: Invoke test-specialist Agent

**EXECUTE NOW - Invoke test-specialist with Behavioral Injection**:

Use the Task tool to invoke test-specialist agent with artifact context from Phase 0:

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Execute comprehensive test suite using test-specialist protocol"
  prompt: |
    Read and follow the behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/test-specialist.md

    You are acting as a Test Specialist Agent.

    CONTEXT:
    - Implementation Phase Complete: All phases implemented
    - Plan Path: ${IMPLEMENTATION_PLAN_PATH}
    - Topic Path: ${TOPIC_PATH}
    - Modified Files: ${FILES_MODIFIED}

    TASK:
    Execute comprehensive test suite for the implemented feature.

    TEST SCOPE:
    - Run full test suite (not just unit tests)
    - Include integration tests if available
    - Execute regression tests for modified files
    - Verify all test types per project standards

    ARTIFACT MANAGEMENT (CRITICAL - From Phase 0 Location Context):
    - Save full test output to: ${ARTIFACT_OUTPUTS}test_results.txt
    - Save coverage report (if available) to: ${ARTIFACT_OUTPUTS}coverage/
    - Return ONLY metadata summary (not full output) to orchestrator

    TEST DISCOVERY:
    - Check CLAUDE.md Testing Protocols section for test commands
    - Use project-specific test patterns
    - Fall back to framework defaults only if CLAUDE.md incomplete

    REQUIRED OUTPUT FORMAT:
    You MUST return structured test results in this format:

    TEST_RESULTS_START
    tests_passing: true|false
    total_tests: N
    passed: N
    passed_pct: X.X
    failed: N
    failed_pct: Y.Y
    skipped: N
    duration: "Xs"
    coverage: "X%" (if available)
    test_output_path: "${ARTIFACT_OUTPUTS}test_results.txt"
    TEST_RESULTS_END

    [If tests_passing=false, also include:]
    FAILED_TESTS_START
    - test_name: "test_auth_validation"
      location: "auth.lua:42"
      error_type: "assertion"
      error_message: "Expected true, got false"
    - test_name: "test_session_timeout"
      location: "session.lua:67"
      error_type: "timeout"
      error_message: "Test exceeded 5s timeout"
    FAILED_TESTS_END

    CRITICAL: Context Reduction Pattern
    - Full test output (10,000+ tokens) MUST be saved to test_output_file
    - Return ONLY structured summary (<100 tokens) to orchestrator
    - DO NOT include full test output or stack traces in return message

    Follow all test-specialist protocol requirements (5 steps).
}
```

**MANDATORY VERIFICATION CHECKPOINT**:

```bash
# Verify test-specialist created test output file
TEST_OUTPUT="${ARTIFACT_OUTPUTS}test_results.txt"

if [ ! -f "$TEST_OUTPUT" ]; then
  echo "ERROR: Test output not created by test-specialist at $TEST_OUTPUT"
  echo "FALLBACK: Creating minimal test report"

  # Create fallback test output
  mkdir -p "${ARTIFACT_OUTPUTS}"
  cat > "$TEST_OUTPUT" <<'EOF'
# Test Results

## Summary
Minimal test report created by fallback mechanism.
test-specialist agent failed to save full test output.

## Status
- Total Tests: Unknown
- Status: Manual verification required

## Recommendation
Review test execution logs and manually verify test results.
EOF
fi

# Verify coverage directory if coverage was reported
if [ -n "${COVERAGE}" ] && [ "${COVERAGE}" != "0" ]; then
  COVERAGE_DIR="${ARTIFACT_OUTPUTS}coverage"
  if [ ! -d "$COVERAGE_DIR" ]; then
    echo "WARNING: Coverage reported but coverage directory missing at $COVERAGE_DIR"
    echo "FALLBACK: Creating coverage directory for future reports"
    mkdir -p "$COVERAGE_DIR"
  fi
fi

echo "✓ VERIFIED: Test output artifacts validated"
```

### Step 2: Extract and Parse Test Results

**EXECUTE NOW - Parse test-specialist Response**:

Extract structured test results from test-specialist response and store in workflow state:

```bash
# Parse test results from agent response
# Look for TEST_RESULTS_START ... TEST_RESULTS_END block

# Extract required fields
TESTS_PASSING=$(echo "$TEST_SPECIALIST_RESPONSE" | grep "tests_passing:" | awk '{print $2}')
TOTAL_TESTS=$(echo "$TEST_SPECIALIST_RESPONSE" | grep "total_tests:" | awk '{print $2}')
PASSED_TESTS=$(echo "$TEST_SPECIALIST_RESPONSE" | grep "^passed:" | awk '{print $2}')
FAILED_TESTS=$(echo "$TEST_SPECIALIST_RESPONSE" | grep "^failed:" | awk '{print $2}')
SKIPPED_TESTS=$(echo "$TEST_SPECIALIST_RESPONSE" | grep "skipped:" | awk '{print $2}')
TEST_DURATION=$(echo "$TEST_SPECIALIST_RESPONSE" | grep "duration:" | awk '{print $2}')
TEST_COVERAGE=$(echo "$TEST_SPECIALIST_RESPONSE" | grep "coverage:" | awk '{print $2}')
TEST_OUTPUT_PATH=$(echo "$TEST_SPECIALIST_RESPONSE" | grep "test_output_path:" | awk '{print $2}')

# Calculate percentages
if [ "$TOTAL_TESTS" -gt 0 ]; then
  PASSED_PCT=$(awk "BEGIN {printf \"%.1f\", ($PASSED_TESTS / $TOTAL_TESTS) * 100}")
  FAILED_PCT=$(awk "BEGIN {printf \"%.1f\", ($FAILED_TESTS / $TOTAL_TESTS) * 100}")
else
  PASSED_PCT="0.0"
  FAILED_PCT="0.0"
fi

# Parse failed test details if tests failed
if [ "$TESTS_PASSING" = "false" ]; then
  # Extract FAILED_TESTS_START ... FAILED_TESTS_END block
  FAILED_TEST_DETAILS=$(echo "$TEST_SPECIALIST_RESPONSE" | \
    sed -n '/FAILED_TESTS_START/,/FAILED_TESTS_END/p' | \
    grep -v "FAILED_TESTS_")
fi

echo "Test Results Extracted:"
echo "- Tests Passing: $TESTS_PASSING"
echo "- Total Tests: $TOTAL_TESTS"
echo "- Passed: $PASSED_TESTS ($PASSED_PCT%)"
echo "- Failed: $FAILED_TESTS ($FAILED_PCT%)"
echo "- Duration: $TEST_DURATION"
echo "- Coverage: $TEST_COVERAGE"
```

### Step 3: Display Test Summary and Conditional Branch

**EXECUTE NOW - Display Test Summary**:

```bash
echo ""
echo "═══════════════════════════════════════════════════════"
echo "PHASE 6: Comprehensive Testing Complete"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "Test Suite Results:"
echo "  Total Tests: $TOTAL_TESTS"
echo "  ✓ Passed: $PASSED_TESTS ($PASSED_PCT%)"
echo "  ✗ Failed: $FAILED_TESTS ($FAILED_PCT%)"
echo "  ⊘ Skipped: $SKIPPED_TESTS"
echo "  Duration: $TEST_DURATION"
if [ -n "$TEST_COVERAGE" ]; then
  echo "  Coverage: $TEST_COVERAGE"
fi
echo ""
echo "Full test output: $TEST_OUTPUT_PATH"
if [ -d "${ARTIFACT_OUTPUTS}coverage/" ]; then
  echo "Coverage report: ${ARTIFACT_OUTPUTS}coverage/index.html"
fi
echo ""
```

**EXECUTE NOW - Conditional Branching Logic**:

```bash
if [ "$TESTS_PASSING" = "true" ]; then
  echo "✓ All tests passing, skipping debugging phase"
  echo ""
  echo "Next Phase: Documentation (Phase 6)"
  echo "═══════════════════════════════════════════════════════"

  # Set flag to skip debugging
  DEBUGGING_SKIPPED=true
  DEBUGGING_REASON="tests_passing"

  # Jump to Documentation Phase
  # (Skip Debugging Loop section entirely)

else
  echo "⚠ $FAILED_TESTS tests failed, proceeding to debugging phase"
  echo ""
  echo "Next Phase: Debugging Loop (Phase 5)"
  echo ""
  echo "Failed Tests:"
  echo "$FAILED_TEST_DETAILS" | head -3  # Show top 3 failures
  echo "═══════════════════════════════════════════════════════"

  # Set flag to invoke debugging
  DEBUGGING_SKIPPED=false
  DEBUGGING_REASON="tests_failing"

  # Store test failure context for debugging phase
  ERROR_MESSAGE="$FAILED_TESTS test(s) failed in Phase 6 (Testing)"
  FAILED_TEST_LIST="$FAILED_TEST_DETAILS"

  # Proceed to Debugging Loop (next section)
fi
```

---

## Phase 6: Documentation Phase (Sequential Execution)

This phase completes the workflow by updating project documentation, generating a comprehensive workflow summary with performance metrics, establishing bidirectional cross-references between all artifacts, and optionally creating a pull request.

### Step 1: Prepare Documentation Context

GATHER workflow artifacts and build documentation context structure for the doc-writer agent.

**EXECUTE NOW: Gather Workflow Artifacts**

EXTRACT the following from workflow_state and prior phase checkpoints:

1. **Research report paths** (from research phase checkpoint, if completed)
2. **Implementation plan path** (from planning phase checkpoint)
3. **Implementation status** (from implementation phase checkpoint)
4. **Test results** (from Phase 6 testing checkpoint)
5. **Debug report paths** (from Phase 5 debugging checkpoint, if invoked)
6. **Modified files list** (from implementation agent output)

BUILD the documentation context structure:

```yaml
documentation_context:
  # From workflow initialization
  workflow_description: "[Original user request]"
  workflow_type: "feature|refactor|debug|investigation"
  project_name: "[generated project name]"

  # From research phase (if completed)
  research_reports: [
    "specs/reports/existing_patterns/001_report.md",
    "specs/reports/security_practices/001_report.md"
  ]
  research_topics: ["existing_patterns", "security_practices"]

  # From planning phase
  plan_path: "specs/plans/NNN_feature_name.md"
  plan_number: NNN
  phase_count: N

  # From implementation phase
  implementation_status:
    tests_passing: true
    phases_completed: "N/N"
    files_modified: [
      "file1.ext",
      "file2.ext"
    ]
    git_commits: [
      "hash1",
      "hash2"
    ]

  # From Phase 6 (Testing)
  test_results:
    tests_passing: true|false
    total_tests: N
    passed: N (X%)
    failed: N (Y%)
    duration: "Xs"
    coverage: "X%"
    test_output_path: "specs/NNN_topic/outputs/test_results.txt"

  # From Phase 5 (Debugging - if invoked)
  debug_reports: [
    "debug/phase1_failures/001_config_init.md"
  ]
  debug_iterations: N
  issues_resolved: [
    "Issue 1 description",
    "Issue 2 description"
  ]

  # Current phase
  current_phase: "documentation"
```

**VERIFICATION CHECKLIST**:
- [ ] workflow_description extracted from state
- [ ] All phase outputs collected (research, planning, implementation, debugging)
- [ ] File paths verified (all referenced files exist)
- [ ] Context structure complete

#### Step 2: Calculate Performance Metrics

CALCULATE workflow timing and performance metrics explicitly.

**EXECUTE NOW: Calculate Performance Metrics**

COMPUTE workflow performance using these explicit algorithms:

1. **Total Workflow Time**:
   ```
   total_time = current_timestamp - workflow_start_timestamp
   total_minutes = total_time / 60
   total_hours = total_minutes / 60
   formatted_duration = sprintf("%02d:%02d:%02d", hours, minutes, seconds)
   ```

2. **Phase Breakdown**:
   For each completed phase, calculate:
   ```
   phase_duration = phase_end_timestamp - phase_start_timestamp
   phase_minutes = phase_duration / 60
   ```

3. **Parallelization Metrics** (if research phase completed):
   ```
   parallel_agents = count(research_reports)
   estimated_sequential_time = parallel_agents × average_research_time
   actual_parallel_time = research_phase_duration
   time_saved = estimated_sequential_time - actual_parallel_time
   time_saved_percentage = (time_saved / estimated_sequential_time) × 100
   ```

4. **Error Recovery Metrics** (if debugging occurred):
   ```
   total_errors = count(debug_reports)
   auto_recovered = total_errors (if tests eventually passed)
   manual_interventions = 0 (if no user escalation)
   recovery_success_rate = (auto_recovered / total_errors) × 100
   ```

BUILD the performance data structure:

```yaml
performance_summary:
  # Time metrics
  total_workflow_time: "[HH:MM:SS format]"
  total_minutes: N

  # Phase breakdown
  phase_times:
    research: "[HH:MM:SS or 'Skipped']"
    planning: "[HH:MM:SS]"
    implementation: "[HH:MM:SS]"
    debugging: "[HH:MM:SS or 'Not needed']"
    documentation: "[current phase]"

  # Parallel execution metrics (if research completed)
  parallelization_metrics:
    parallel_research_agents: N
    estimated_sequential_time: "[minutes]"
    actual_parallel_time: "[minutes]"
    time_saved_estimate: "[N% saved vs sequential]"

  # Error recovery metrics (if debugging occurred)
  error_recovery:
    total_errors: N
    auto_recovered: N
    manual_interventions: N
    recovery_success_rate: "[N%]"
```

**VERIFICATION CHECKLIST**:
- [ ] All timestamps extracted from checkpoints
- [ ] Duration calculations correct (no negative times)
- [ ] Parallelization metrics calculated (if applicable)
- [ ] Error recovery metrics calculated (if debugging occurred)

#### Step 3: Invoke Doc-Writer Agent

INVOKE the doc-writer agent with complete inline prompt including workflow summary template and cross-reference instructions.

**EXECUTE NOW: Invoke Doc-Writer Agent**

USE the Task tool to invoke the doc-writer agent NOW.

Task tool invocation:

```yaml
subagent_type: general-purpose

description: "Update documentation and generate workflow summary using doc-writer protocol"

prompt: |
  Read and follow the behavioral guidelines from:
  /home/benjamin/.config/.claude/agents/doc-writer.md

  You are acting as a Documentation Writer Agent with the tools and constraints
  defined in that file.

  ## Documentation Task: Complete Workflow Documentation

  ### Workflow Context
  - **Original Request**: [workflow_description]
  - **Workflow Type**: [workflow_type]
  - **Project Name**: [project_name]
  - **Completion Date**: [current_date YYYY-MM-DD]

  ### Artifacts Generated

  **Research Reports** (if research phase completed):
  [For each report in research_reports:]
  - [report_path] - [topic]

  **Implementation Plan**:
  - Path: [plan_path]
  - Number: [plan_number]
  - Phases: [phase_count]

  **Implementation Status**:
  - Tests: [passing/fixed_after_debugging]
  - Phases Completed: [N/N]
  - Files Modified: [count] files
  - Git Commits: [count] commits

  **Debug Reports** (if debugging occurred):
  [For each report in debug_reports:]
  - [debug_report_path] - [issue resolved]
  - Iterations: [debug_iterations]

  ### Performance Metrics
  - Total Duration: [total_workflow_time HH:MM:SS]
  - Research Time: [research_phase_time or "Skipped"]
  - Planning Time: [planning_phase_time]
  - Implementation Time: [implementation_phase_time]
  - Debugging Time: [debugging_phase_time or "Not needed"]
  - Parallelization Savings: [time_saved_percentage% or "N/A"]
  - Error Recovery Rate: [recovery_success_rate% or "100% (no errors)"]

  ### ARTIFACT ORGANIZATION (CRITICAL - From Phase 0 Location Context)

  - **Summary Path**: ${ARTIFACT_SUMMARIES}${TOPIC_NUMBER}_workflow_summary.md
  - **Topic Number**: ${TOPIC_NUMBER}
  - **Topic Name**: ${TOPIC_NAME}
  - **Topic Path**: ${TOPIC_PATH}
  - **All Artifact Paths** (for cross-references):
    - Reports: ${ARTIFACT_REPORTS}
    - Plans: ${ARTIFACT_PLANS}
    - Debug: ${ARTIFACT_DEBUG}
    - Summaries: ${ARTIFACT_SUMMARIES}
    - Outputs: ${ARTIFACT_OUTPUTS}

  **CRITICAL REQUIREMENTS**:
  - Use the summary path from location context (NOT calculated manually)
  - DO NOT use relative paths - all paths are absolute
  - DO NOT calculate summary directory from plan path
  - Summary metadata MUST include topic information (see below)

  ### Documentation Requirements

  1. **Update Project Documentation**:
     - Review files modified during implementation
     - Update relevant README files
     - Add usage examples where appropriate
     - Ensure documentation follows CLAUDE.md standards

**EXECUTE NOW - Generate Workflow Summary**

YOU MUST create a comprehensive workflow summary documenting the entire orchestration. This is NOT optional.

**WHY THIS MATTERS**: The summary is the permanent record of what was accomplished. Without it, the orchestration workflow is undocumented and non-reproducible. The summary enables future reference, knowledge transfer, and workflow improvement.

**MANDATORY INPUTS**:
- Workflow description (original user request)
- Research report paths (from Research Phase, if completed)
- Implementation plan path (from Planning Phase)
- Implementation status (from Implementation Phase)
- All phase metrics (timing, file counts, etc.)

**EXECUTE NOW - Get Summary Path from Phase 0 Location Context**:

```bash
# STEP 1: Use summary path from Phase 0 location context (no manual calculation needed)
# Phase 0 already created the summaries/ directory and determined the topic number

SUMMARY_PATH="${ARTIFACT_SUMMARIES}${TOPIC_NUMBER}_workflow_summary.md"

echo "Summary will be created at: $SUMMARY_PATH"
echo "(Path from Phase 0 location context - no manual calculation needed)"
```

  2. **Create Workflow Summary**:
     Create a comprehensive workflow summary file at:
     `[plan_directory]/specs/summaries/[plan_number]_workflow_summary.md`

     **EXECUTE NOW - Create Summary File**:

     Use this exact template:

     ```markdown
     # Workflow Summary: [Feature/Task Name]

     ## Metadata
     - **Date Completed**: [YYYY-MM-DD]
     - **Topic Number**: ${TOPIC_NUMBER}
     - **Topic Name**: ${TOPIC_NAME}
     - **Topic Path**: ${TOPIC_PATH}
     - **Workflow Type**: [feature|refactor|debug|investigation]
     - **Original Request**: [workflow_description]
     - **Completion Status**: [success|success_with_debugging|partial]

     ## Artifact Organization
     All artifacts for this workflow are organized in:
     - **Reports**: ${ARTIFACT_REPORTS}
     - **Plans**: ${ARTIFACT_PLANS}
     - **Summaries**: ${ARTIFACT_SUMMARIES}
     - **Debug**: ${ARTIFACT_DEBUG} (if debugging occurred)
     - **Outputs**: ${ARTIFACT_OUTPUTS}
     - **Total Duration**: [HH:MM:SS]

     ## Workflow Execution

     ### Phases Completed
     - [x] Research (parallel) - [duration or "Skipped"]
     - [x] Planning (sequential) - [duration]
     - [x] Implementation (adaptive) - [duration]
     - [x] Debugging (conditional) - [duration or "Not needed"]
     - [x] Documentation (sequential) - [duration]

     ### Artifacts Generated

     **Research Reports**:
     [If research phase completed, list each report:]
     - [Report 1: path - brief description]
     - [Report 2: path - brief description]

     [If no research: "(No research phase - direct implementation)"]

     **Implementation Plan**:
     - Path: [plan_path]
     - Phases: [phase_count]
     - Complexity: [Low|Medium|High]
     - Link: [relative link to plan file]

     **Debug Reports**:
     [If debugging occurred, list each report:]
     - [Debug report 1: path - issue addressed]

     [If no debugging: "(No debugging needed - tests passed on first run)"]

     ## Implementation Overview

     ### Key Changes
     **Files Created**:
     [For each new file:]
     - [new_file.ext] - [brief purpose]

     **Files Modified**:
     [For each modified file:]
     - [modified_file.ext] - [changes made]

     **Files Deleted**:
     [For each deleted file:]
     - [deleted_file.ext] - [reason for deletion]

     ### Technical Decisions
     [Key architectural or technical decisions made during workflow]
     - Decision 1: [what and why]
     - Decision 2: [what and why]

     ## Test Results

     **Final Status**: ✓ All tests passing

     [If debugging occurred:]
     **Debugging Summary**:
     - Iterations required: [debug_iterations]
     - Issues resolved:
       1. [Issue 1 and fix]
       2. [Issue 2 and fix]

     ## Performance Metrics

     ### Workflow Efficiency
     - Total workflow time: [HH:MM:SS]
     - Estimated manual time: [HH:MM:SS calculated estimate]
     - Time saved: [N%]

     ### Phase Breakdown
     | Phase | Duration | Status |
     |-------|----------|--------|
     | Research | [time] | [Completed/Skipped] |
     | Planning | [time] | Completed |
     | Implementation | [time] | Completed |
     | Debugging | [time] | [Completed/Not needed] |
     | Documentation | [time] | Completed |

     ### Parallelization Effectiveness
     [If research completed:]
     - Research agents used: [N]
     - Parallel vs sequential time: [N% faster]

     [If no research: "No parallel execution in this workflow"]

     ### Error Recovery
     [If debugging occurred:]
     - Total errors encountered: [N]
     - Automatically recovered: [N]
     - Manual interventions: [0 or N]
     - Recovery success rate: [N%]

     [If no errors: "Zero errors - clean implementation"]

     ## Cross-References

     ### Research Phase
     [If applicable:]
     This workflow incorporated findings from:
     - [Report 1 path and title]
     - [Report 2 path and title]

     ### Planning Phase
     Implementation followed the plan at:
     - [Plan path and title]

     ### Related Documentation
     Documentation updated includes:
     - [Doc 1 path]
     - [Doc 2 path]

     ## Lessons Learned

     ### What Worked Well
     - [Success 1 - what went smoothly]
     - [Success 2 - effective strategies]

     ### Challenges Encountered
     - [Challenge 1 and how it was resolved]
     - [Challenge 2 and resolution approach]

     ### Recommendations for Future
     - [Recommendation 1 for similar workflows]
     - [Recommendation 2 for improvements]

     ## Notes

     [Any additional context, caveats, or important information about this workflow]

     ---

     *Workflow orchestrated using /orchestrate command*
     *For questions or issues, refer to the implementation plan and research reports linked above.*
     ```

**MANDATORY VERIFICATION - Summary File Created**

After creating the summary file, YOU MUST verify it was created successfully. This verification is NOT optional.

**WHY THIS MATTERS**: The summary file is the permanent record of the workflow. If it's not created or is incomplete, the entire orchestration effort is undocumented.

**EXECUTE NOW - Verify Summary File**:

```bash
# STEP 1: Verify summary exists
if [ ! -f "$SUMMARY_PATH" ]; then
  echo "❌ CRITICAL ERROR: Summary file not created"
  echo "Expected path: $SUMMARY_PATH"
  exit 1
fi

echo "✓ VERIFIED: Summary file exists at $SUMMARY_PATH"

# STEP 2: Verify summary has required sections
REQUIRED_SECTIONS=("Metadata" "Workflow Execution" "Artifacts Generated" "Cross-References")
MISSING_SECTIONS=()

for section in "${REQUIRED_SECTIONS[@]}"; do
  if ! grep -q "## $section" "$SUMMARY_PATH"; then
    MISSING_SECTIONS+=("$section")
  fi
done

if [ ${#MISSING_SECTIONS[@]} -gt 0 ]; then
  echo "⚠️  WARNING: Summary missing sections: ${MISSING_SECTIONS[*]}"
  echo "Summary may be incomplete"
fi

echo "✓ VERIFIED: Summary structure complete"
```

**CRITICAL REQUIREMENTS**:
- YOU MUST create summary file (not optional)
- YOU MUST include all cross-references
- YOU MUST verify file created
- Summary MUST use the template structure

**CHECKPOINT REQUIREMENT**:
```
CHECKPOINT: Documentation phase complete
- Summary created: ✓
- Summary path: $SUMMARY_PATH
- Cross-references included: ✓
- All phases documented: ✓
- Proceeding to: Final workflow checkpoint
```

  3. **Create Cross-References**:

     a. **Update Implementation Plan** ([plan_path]):
        Add at bottom of plan file:
        ```markdown
        ## Implementation Summary
        This plan was executed on [YYYY-MM-DD]. See workflow summary:
        - [Summary path link]

        Status: ✅ COMPLETE
        - Duration: [HH:MM:SS]
        - Tests: All passing
        - Files modified: [N]
        ```

     b. **Update Research Reports** (if any):
        For each report in research_reports, add:
        ```markdown
        ## Implementation Reference
        Findings from this report were incorporated into:
        - [Plan path] - Implementation plan
        - [Summary path] - Workflow execution summary
        - Date: [YYYY-MM-DD]
        ```

     c. **Update Debug Reports** (if any):
        For each report in debug_reports, add:
        ```markdown
        ## Resolution Summary
        This issue was resolved during:
        - Workflow: [workflow_description]
        - Iteration: [N]
        - Summary: [Summary path link]
        ```

  ### Output Requirements

  Return results in this format:

  ```
  PROGRESS: Updating project documentation...
  PROGRESS: Updating [file1.ext]...
  PROGRESS: Updating [file2.ext]...
  PROGRESS: Creating workflow summary...
  PROGRESS: Adding cross-references...

  DOCUMENTATION_RESULTS:
  - updated_files: [list of documentation files modified]
  - readme_updates: [list of README files updated]
  - workflow_summary_created: [summary file path]
  - cross_references_added: [count]
  - documentation_complete: true
  ```

  ### Quality Checklist
  - [ ] Purpose clearly stated in updated docs
  - [ ] Usage examples included where appropriate
  - [ ] Cross-references added bidirectionally
  - [ ] Unicode box-drawing used (not ASCII art)
  - [ ] No emojis in content
  - [ ] Code examples have syntax highlighting
  - [ ] Navigation links updated
  - [ ] CommonMark compliant
  - [ ] Workflow summary follows template exactly
  - [ ] All cross-references validated (files exist)
```

**Monitoring During Agent Execution**:
- Watch for `PROGRESS: <message>` markers in agent output
- Display progress updates to user in real-time
- Verify summary file creation
- Validate cross-reference updates

**VERIFICATION CHECKLIST**:
- [ ] Task tool invoked with doc-writer protocol
- [ ] Complete prompt provided inline (not referenced)
- [ ] Workflow summary template inlined in prompt
- [ ] Cross-reference instructions explicit
- [ ] Agent execution monitored (progress markers)

#### Step 4: Validate Summary Creation

**MANDATORY VERIFICATION - Summary File Created in Correct Location**:

```bash
EXPECTED_SUMMARY_PATH="${ARTIFACT_SUMMARIES}${TOPIC_NUMBER}_workflow_summary.md"

if [[ ! -f "$EXPECTED_SUMMARY_PATH" ]]; then
  echo "ERROR: Workflow summary not created at expected location: $EXPECTED_SUMMARY_PATH"
  echo ""

  # FALLBACK MECHANISM: Search for summary file in common locations
  echo "Searching for summary file in topic directory..."
  FOUND_SUMMARY=$(find "${TOPIC_PATH}" -name "*workflow_summary.md" -o -name "*summary.md" 2>/dev/null | head -n 1)

  if [[ -n "$FOUND_SUMMARY" ]]; then
    echo "⚠️  Found summary in wrong location: $FOUND_SUMMARY"
    echo "Moving to correct location: $EXPECTED_SUMMARY_PATH"

    mkdir -p "$(dirname "$EXPECTED_SUMMARY_PATH")"
    mv "$FOUND_SUMMARY" "$EXPECTED_SUMMARY_PATH"

    echo "✓ Summary moved to correct location"
  else
    echo "CRITICAL: Workflow summary not found anywhere in topic directory"
    echo "Creating minimal summary template as fallback..."

    mkdir -p "$(dirname "$EXPECTED_SUMMARY_PATH")"
    cat > "$EXPECTED_SUMMARY_PATH" <<EOF
# Workflow Summary: ${WORKFLOW_DESCRIPTION}

## Metadata
- **Date Completed**: $(date -u +%Y-%m-%d)
- **Topic Number**: ${TOPIC_NUMBER}
- **Topic Name**: ${TOPIC_NAME}
- **Topic Path**: ${TOPIC_PATH}
- **Workflow Type**: feature
- **Original Request**: ${WORKFLOW_DESCRIPTION}
- **Completion Status**: partial (doc-writer failed to create summary)

## Artifact Organization
All artifacts for this workflow are organized in:
- **Reports**: ${ARTIFACT_REPORTS}
- **Plans**: ${ARTIFACT_PLANS}
- **Summaries**: ${ARTIFACT_SUMMARIES}
- **Debug**: ${ARTIFACT_DEBUG}
- **Outputs**: ${ARTIFACT_OUTPUTS}

## Note
This summary was auto-generated as a fallback because the doc-writer agent
did not create the summary file. Manual documentation recommended.
EOF

    echo "✓ Minimal summary created at: $EXPECTED_SUMMARY_PATH"
  fi
else
  echo "✓ VERIFIED: Workflow summary validated at: $EXPECTED_SUMMARY_PATH"
fi

# Verify summary includes topic metadata
echo "Verifying summary metadata includes topic information..."
if grep -q "Topic Number:" "$EXPECTED_SUMMARY_PATH" && \
   grep -q "Topic Path:" "$EXPECTED_SUMMARY_PATH"; then
  echo "✓ VERIFIED: Summary includes topic metadata"
else
  echo "⚠️  WARNING: Summary missing topic metadata - may need manual update"
fi

echo ""
```

#### Step 5: Extract Documentation Results

PARSE the doc-writer agent output to extract and validate documentation results.

**EXECUTE NOW: Extract and Validate Documentation Results**

1. **Locate Results Block**:
   Search agent output for "DOCUMENTATION_RESULTS:" marker

2. **Extract Results Data**:
   ```yaml
   documentation_results:
     updated_files: [
       "file1.ext",
       "file2.ext"
     ]
     readme_updates: [
       "dir1/README.md",
       "dir2/README.md"
     ]
     workflow_summary_created: "specs/summaries/NNN_workflow_summary.md"
     cross_references_added: N
     documentation_complete: true
   ```

3. **Validate Results**:
   - At least one documentation file updated (updated_files not empty)
   - Workflow summary file created and exists
   - Cross-references count > 0 (at least plan → summary link)
   - documentation_complete is true

4. **Store in Workflow State**:
   ```yaml
   workflow_state.documentation_paths: [
     "specs/summaries/NNN_workflow_summary.md",
     ...updated_files,
     ...readme_updates
   ]
   ```

**Validation Checklist**:
- [ ] At least one documentation file updated
- [ ] Workflow summary file exists at expected path
- [ ] Summary file follows template structure (verify key sections present)
- [ ] Cross-references include all workflow artifacts
- [ ] Plan file updated with "Implementation Summary" section
- [ ] Research reports updated with "Implementation Reference" (if applicable)
- [ ] Debug reports updated with "Resolution Summary" (if applicable)
- [ ] No broken links (all referenced paths valid)
- [ ] Documentation follows project standards (CLAUDE.md compliance)

**Error Handling**:
```yaml
if documentation_complete == false:
  ERROR: "Documentation phase incomplete"
  → Check agent output for error messages
  → Verify doc-writer has Write and Edit tool access
  → Retry with clarified instructions if recoverable
  → Escalate to user if persistent failure

if workflow_summary_created == null:
  ERROR: "Workflow summary not created"
  → Check specs/summaries/ directory exists
  → Verify plan_number extracted correctly
  → Retry summary creation explicitly

if cross_references_added == 0:
  WARNING: "No cross-references created"
  → Cross-reference step may have failed
  → Manually update files if needed
  → Note in workflow completion message
```

**VERIFICATION CHECKLIST**:
- [ ] Results extracted from agent output
- [ ] All expected fields present
- [ ] Validation checklist completed
- [ ] Error handling triggered if issues detected

#### Step 5: Verify Cross-References

VALIDATE that bidirectional cross-references were created correctly by the doc-writer agent.

**EXECUTE NOW: Verify Bidirectional Cross-References**

1. **Read Implementation Plan** ([plan_path]):
   ```
   USE Read tool to open plan file
   SEARCH for "## Implementation Summary" section
   VERIFY section exists and includes:
   - Summary path link
   - Completion date
   - Status (COMPLETE)
   ```

2. **Read Workflow Summary** ([summary_path]):
   ```
   USE Read tool to open summary file
   SEARCH for "## Cross-References" section
   VERIFY section includes:
   - Research reports (if applicable)
   - Implementation plan
   - Related documentation
   ```

3. **Read Research Reports** (if any):
   ```
   FOR each report in research_reports:
     USE Read tool to open report file
     SEARCH for "## Implementation Reference" section
     VERIFY section exists and includes:
     - Plan path link
     - Summary path link
     - Completion date
   ```

4. **Read Debug Reports** (if any):
   ```
   FOR each report in debug_reports:
     USE Read tool to open debug report file
     SEARCH for "## Resolution Summary" section
     VERIFY section includes:
     - Workflow description
     - Summary path link
   ```

**Cross-Reference Validation Matrix**:

| From | To | Link Type | Verified |
|------|-----|-----------|----------|
| Plan | Summary | Implementation Summary section | [ ] |
| Summary | Plan | Cross-References section | [ ] |
| Summary | Reports | Cross-References section | [ ] |
| Reports | Plan | Implementation Reference section | [ ] |
| Reports | Summary | Implementation Reference section | [ ] |
| Debug | Summary | Resolution Summary section | [ ] |

**If Validation Fails**:
```yaml
if any_validation_fails:
  WARNING: "Cross-reference validation failed"
  → Report which links are missing
  → Attempt manual cross-reference creation
  → Use Edit tool to add missing sections
  → Re-validate after manual fixes
```

**VERIFICATION CHECKLIST**:
- [ ] All plan → summary links verified
- [ ] All summary → plan links verified
- [ ] All summary → report links verified (if applicable)
- [ ] All report → plan/summary links verified (if applicable)
- [ ] All debug → summary links verified (if applicable)
- [ ] Cross-reference matrix complete

#### Step 6: Save Final Checkpoint

CREATE final checkpoint with complete workflow metrics.

**EXECUTE NOW: Save Final Workflow Checkpoint**

USE checkpoint utility:
```bash
.claude/lib/save-checkpoint.sh orchestrate "$PROJECT_NAME" "$CHECKPOINT_DATA"
```

Where CHECKPOINT_DATA is:
```yaml
checkpoint_workflow_complete:
  # Phase identification
  phase_name: "documentation"
  completion_time: [current_timestamp]

  # Documentation outputs
  outputs:
    documentation_updated: [list of updated files]
    workflow_summary_created: "[summary_path]"
    cross_references_added: N
    status: "success"

  # Workflow completion
  next_phase: "complete"
  workflow_status: "success"

  # Complete workflow metrics
  final_metrics:
    # Time metrics
    total_workflow_time: "[HH:MM:SS]"
    total_minutes: N

    # Phase completion
    phases_completed: [
      "research",    # or "skipped"
      "planning",
      "implementation",
      "debugging",   # or "not_needed"
      "documentation"
    ]

    # Artifact counts
    artifacts_generated:
      research_reports: N
      implementation_plan: 1
      workflow_summary: 1
      debug_reports: N
      documentation_updates: N

    # File changes
    files_modified: N
    files_created: N
    files_deleted: N
    git_commits: N

    # Performance
    parallelization_savings: "[N% or 'N/A']"
    error_recovery_success: "[N% or '100% (no errors)']"

  # Complete workflow summary
  workflow_summary:
    research_reports: [list of paths]
    implementation_plan: "[plan_path]"
    workflow_summary: "[summary_path]"
    debug_reports: [list of paths]
    tests_passing: true
    documentation_complete: true
```

**Checkpoint File Location**:
```
.claude/data/checkpoints/orchestrate_${PROJECT_NAME}_${TIMESTAMP}.json
```

**VERIFICATION CHECKLIST**:
- [ ] Checkpoint saved successfully
- [ ] All workflow metrics included
- [ ] Artifact paths recorded
- [ ] Status set to "complete"

#### Step 7: Conditional PR Creation

EVALUATE whether to create a pull request and invoke github-specialist agent if required.

**EXECUTE NOW: Check for PR Creation Flag**

1. **Check for --create-pr Flag**:
   ```
   if "--create-pr" in original_command_arguments:
     pr_creation_required = true
   else:
     pr_creation_required = false
   ```

2. **Prerequisites Check** (if pr_creation_required):
   ```bash
   # Check if gh CLI is available and authenticated
   if ! command -v gh &>/dev/null; then
     echo "Note: gh CLI not installed. Skipping PR creation."
     echo "Install: brew install gh (or equivalent)"
     pr_creation_required = false
   fi

   if ! gh auth status &>/dev/null; then
     echo "Note: gh CLI not authenticated. Skipping PR creation."
     echo "Run: gh auth login"
     pr_creation_required = false
   fi
   ```

3. **Invoke github-specialist Agent** (if pr_creation_required):

   **EXECUTE NOW: Invoke GitHub Specialist Agent**

   USE the Task tool to invoke github-specialist agent NOW.

   Task tool invocation:
   ```yaml
   subagent_type: general-purpose

   description: "Create PR for completed workflow using github-specialist protocol"

   prompt: |
     Read and follow the behavioral guidelines from:
     /home/benjamin/.config/.claude/agents/github-specialist.md

     You are acting as a GitHub Specialist Agent with the tools and constraints
     defined in that file.

     ## PR Creation Task: Workflow Completion Pull Request

     ### Workflow Context
     - **Plan**: [absolute path to implementation plan]
     - **Branch**: [current branch name from git]
     - **Base**: main (or master, detect from repo)
     - **Summary**: [absolute path to workflow summary]
     - **Original Request**: [workflow_description]

     ### PR Description Content

     Create a comprehensive PR description following this structure:

     ```markdown
     # [Feature/Task Name]

     ## Summary
     [Brief 1-2 sentence summary of what was implemented]

     ## Workflow Overview
     This PR was created through a complete /orchestrate workflow:

     **Research Phase**: [N reports generated or "Skipped"]
     [If research completed:]
     - [Report 1 title and key finding]
     - [Report 2 title and key finding]

     **Planning Phase**: [Phase count]-phase implementation plan
     - Complexity: [Low|Medium|High]
     - See: [plan path]

     **Implementation Phase**: All [N] phases completed successfully
     - Tests: [All passing or Fixed after M debug iterations]
     - Files modified: [N]
     - Commits: [N]

     **Debugging Phase**: [N iterations or "Not needed"]
     [If debugging occurred:]
     - Issues resolved: [M]
     - See debug reports: [debug report paths]

     **Documentation Phase**: [N] files updated
     - Documentation: [list updated files]
     - Workflow summary: [summary path]

     ## Performance Metrics
     - **Total Duration**: [HH:MM:SS]
     - **Parallelization Savings**: [N% or "N/A"]
     - **Error Recovery**: [success rate or "100% (no errors)"]

     ## File Changes
     [Use git diff --stat to show change summary]

     **Files Created**: [N]
     **Files Modified**: [N]
     **Files Deleted**: [N]

     ## Cross-References

     **Implementation Plan**: [plan path]
     **Workflow Summary**: [summary path]
     [If research:]
     **Research Reports**:
     - [report 1 path]
     - [report 2 path]
     [If debugging:]
     **Debug Reports**:
     - [debug report 1 path]

     ## Test Results
     ✓ All tests passing

     [If debugging occurred:]
     Fixed issues:
     1. [Issue 1 description]
     2. [Issue 2 description]

     ## Checklist
     - [x] All implementation phases completed
     - [x] Tests passing
     - [x] Documentation updated
     - [x] Code follows project standards
     - [ ] Ready for review
     ```

     ### Output Required

     Return PR details in this format:
     ```
     PR_CREATED:
     - url: [PR URL]
     - number: [PR number]
     - branch: [feature branch]
     - base: [base branch]
     ```
   ```

4. **Capture PR URL** (if created):
   ```
   PARSE github-specialist output for PR_CREATED block
   EXTRACT pr_url and pr_number

   STORE in workflow_state:
   workflow_state.pr_url = pr_url
   workflow_state.pr_number = pr_number
   ```

5. **Update Workflow Summary with PR Link** (if created):
   ```
   USE Edit tool to update workflow summary file
   ADD section at bottom:

   ## Pull Request
   - **PR**: [pr_url]
   - **Number**: #[pr_number]
   - **Created**: [YYYY-MM-DD]
   - **Status**: Open
   ```

6. **Graceful Degradation** (if PR creation fails):
   ```yaml
   if pr_creation_fails:
     LOG error message from github-specialist

     DISPLAY manual PR creation command:
     ```
     To create PR manually:

     gh pr create \
       --title "feat: [feature name]" \
       --body-file [pr_description_file] \
       --base main
     ```

     CONTINUE workflow (don't block on PR failure)
   ```

**VERIFICATION CHECKLIST**:
- [ ] --create-pr flag checked
- [ ] Prerequisites validated (gh CLI, auth)
- [ ] github-specialist agent invoked (if required)
- [ ] PR URL captured and stored
- [ ] Workflow summary updated with PR link
- [ ] Error handled gracefully (if PR creation fails)

**State Management**:

UPDATE workflow_state after documentation phase completes:

```yaml
workflow_state.current_phase = "complete"
workflow_state.execution_tracking.phase_start_times["documentation"] = [doc start timestamp]
workflow_state.execution_tracking.phase_end_times["documentation"] = [current timestamp]
workflow_state.execution_tracking.agents_invoked += 1  # doc-writer agent
workflow_state.execution_tracking.agents_invoked += 1  # github-specialist (if PR created)
workflow_state.execution_tracking.files_created += 1  # workflow summary
workflow_state.completed_phases.append("documentation")
workflow_state.context_preservation.documentation_paths = [summary_path, updated_doc_paths...]

# Calculate total duration
workflow_state.performance_metrics.total_duration_seconds =
  workflow_state.execution_tracking.phase_end_times["documentation"] -
  workflow_state.execution_tracking.phase_start_times["analysis"]
```

UPDATE TodoWrite to mark all tasks complete:

```json
{
  "todos": [
    {
      "content": "Analyze workflow and identify research topics",
      "status": "completed",
      "activeForm": "Analyzing workflow and identifying research topics"
    },
    {
      "content": "Execute parallel research phase",
      "status": "completed",
      "activeForm": "Executing parallel research phase"
    },
    {
      "content": "Create implementation plan",
      "status": "completed",
      "activeForm": "Creating implementation plan"
    },
    {
      "content": "Implement features with testing",
      "status": "completed",
      "activeForm": "Implementing features with testing"
    },
    {
      "content": "Debug and fix test failures (if needed)",
      "status": "completed",
      "activeForm": "Debugging and fixing test failures"
    },
    {
      "content": "Generate documentation and workflow summary",
      "status": "completed",
      "activeForm": "Generating documentation and workflow summary"
    }
  ]
}
```

#### Step 8: Workflow Completion Message

OUTPUT final workflow summary to user with comprehensive details.

**EXECUTE NOW: Display Workflow Completion Message**

USE this exact format:

```markdown
┌─────────────────────────────────────────────────────────────┐
│                     WORKFLOW COMPLETE                       │
└─────────────────────────────────────────────────────────────┘

**Duration**: [HH:MM:SS]

**Phases Executed**:
[If research completed:]
✓ Research (parallel) - [duration]
  - Topics: [N]
  - Reports: [report paths]

✓ Planning (sequential) - [duration]
  - Plan: [plan_path]
  - Phases: [N]

✓ Implementation (adaptive) - [duration]
  - Phases completed: [N/N]
  - Files modified: [N]
  - Git commits: [N]

[If debugging occurred:]
✓ Debugging ([N] iterations) - [duration]
  - Issues resolved: [M]
  - Debug reports: [debug report paths]

✓ Documentation (sequential) - [duration]
  - Documentation updates: [N] files
  - Workflow summary: [summary_path]
  - Cross-references: [N] links

**Implementation Results**:
- Files created: [N]
- Files modified: [N]
- Files deleted: [N]
- Tests: ✓ All passing

**Performance Metrics**:
[If parallelization used:]
- Time saved via parallelization: [N%]
[If error recovery occurred:]
- Error recovery: [N/M errors auto-recovered]
[Else:]
- Error-free execution: 100%

**Artifacts Generated**:
[If research:]
- Research reports: [N] reports in [M] topics
[Always:]
- Implementation plan: [plan_path]
- Workflow summary: [summary_path]
[If debugging:]
- Debug reports: [N] reports

[If PR created:]
**Pull Request**:
- PR #[pr_number]: [pr_url]
- Status: Open for review

**Next Steps**:
[If PR created:]
1. Review PR at [pr_url]
2. Request reviews from team members
3. Merge when approved

[Else:]
1. Review workflow summary: [summary_path]
2. Review implementation plan: [plan_path]
3. Consider creating PR with: gh pr create

**Summary**: [summary_path]
Review the workflow summary for complete details, cross-references, and lessons learned.

┌─────────────────────────────────────────────────────────────┐
│  All workflow artifacts saved and cross-referenced.         │
│  Thank you for using /orchestrate!                          │
└─────────────────────────────────────────────────────────────┘
```

**Completion Data to Display**:

Extract from workflow_state and performance_summary:
- Total duration (formatted HH:MM:SS)
- All phase durations (or "Skipped"/"Not needed")
- Artifact counts and paths
- File modification counts
- Test status
- Performance metrics (parallelization, error recovery)
- PR information (if created)

**VERIFICATION CHECKLIST**:
- [ ] Completion message displayed to user
- [ ] All key metrics included
- [ ] Artifact paths provided
- [ ] Next steps suggested
- [ ] Message formatted clearly (Unicode box-drawing)

#### Step 9: Cleanup Final Checkpoint

REMOVE checkpoint file after successful workflow completion.

**EXECUTE NOW: Cleanup Completed Workflow Checkpoint**

```bash
# Delete checkpoint file (workflow complete, no resume needed)
rm -f .claude/data/checkpoints/orchestrate_${PROJECT_NAME}_*.json

# Log completion
echo "[$(date)] Workflow ${PROJECT_NAME} completed successfully" >> .claude/logs/orchestrate.log
```

**Checkpoint Cleanup Logic**:
```yaml
if workflow_status == "success":
  → Delete checkpoint file (no longer needed)
  → Log completion to orchestrate.log

elif workflow_status == "escalated":
  → Keep checkpoint file (user may resume)
  → Move to .claude/data/checkpoints/failed/ for investigation

elif workflow_status == "error":
  → Keep checkpoint file (debugging needed)
  → Archive to .claude/data/checkpoints/failed/
```

**VERIFICATION CHECKLIST**:
- [ ] Checkpoint file removed (if success)
- [ ] Completion logged
- [ ] Failed checkpoints archived (if applicable)

#### Workflow Summary Template (Reference)

The complete workflow summary template is inlined in Step 3 (doc-writer agent prompt) above. This reference section is provided for documentation purposes only.

**Summary Template**:
```markdown
# Workflow Summary: [Feature/Task Name]

## Metadata
- **Date Completed**: [YYYY-MM-DD]
- **Specs Directory**: [path/to/specs/] (from plan metadata)
- **Summary Number**: [NNN] (matches plan number)
- **Workflow Type**: [feature|refactor|debug|investigation]
- **Original Request**: [User's workflow description]
- **Total Duration**: [HH:MM:SS]

## Workflow Execution

### Phases Completed
- [x] Research (parallel) - [duration or "Skipped"]
- [x] Planning (sequential) - [duration]
- [x] Implementation (adaptive) - [duration]
- [x] Debugging (conditional) - [duration or "Not needed"]
- [x] Documentation (sequential) - [duration]

### Artifacts Generated

**Research Reports**:
[If research phase completed]
- [Report 1: path - brief description]
- [Report 2: path - brief description]

**Implementation Plan**:
- Path: [plan_path]
- Phases: N
- Complexity: [Low|Medium|High]
- Link: [relative link to plan file]

**Debug Reports**:
[If debugging occurred]
- [Debug report 1: path - issue addressed]

## Implementation Overview

### Key Changes
**Files Created**:
- [new_file_1.ext] - [brief purpose]
- [new_file_2.ext] - [brief purpose]

**Files Modified**:
- [modified_file_1.ext] - [changes made]
- [modified_file_2.ext] - [changes made]

**Files Deleted**:
- [deleted_file.ext] - [reason for deletion]

### Technical Decisions
[Key architectural or technical decisions made during workflow]
- Decision 1: [what and why]
- Decision 2: [what and why]

## Test Results

**Final Status**: ✓ All tests passing

[If debugging occurred]
**Debugging Summary**:
- Iterations required: N
- Issues resolved:
  1. [Issue 1 and fix]
  2. [Issue 2 and fix]

## Performance Metrics

### Workflow Efficiency
- Total workflow time: [HH:MM:SS]
- Estimated manual time: [HH:MM:SS]
- Time saved: [N%]

### Phase Breakdown
| Phase | Duration | Status |
|-------|----------|--------|
| Research | [time] | [Completed/Skipped] |
| Planning | [time] | Completed |
| Implementation | [time] | Completed |
| Debugging | [time] | [Completed/Not needed] |
| Documentation | [time] | Completed |

### Parallelization Effectiveness
- Research agents used: N
- Parallel vs sequential time: [N% faster]

### Error Recovery
- Total errors encountered: N
- Automatically recovered: N
- Manual interventions: N
- Recovery success rate: [N%]

## Cross-References

### Research Phase
[If applicable]
This workflow incorporated findings from:
- [Report 1 path and title]
- [Report 2 path and title]

### Planning Phase
Implementation followed the plan at:
- [Plan path and title]

### Related Documentation
Documentation updated includes:
- [Doc 1 path]
- [Doc 2 path]

## Lessons Learned

### What Worked Well
- [Success 1]
- [Success 2]

### Challenges Encountered
- [Challenge 1 and how it was resolved]
- [Challenge 2 and how it was resolved]

### Recommendations for Future
- [Recommendation 1]
- [Recommendation 2]

## Notes

[Any additional context, caveats, or important information about this workflow]

---

*Workflow orchestrated using /orchestrate command*
*For questions or issues, refer to the implementation plan and research reports linked above.*
```

#### Step 6: Create Summary File

**File Creation**:
```yaml
action: create_summary_file
location: "[plan_directory]/specs/summaries/NNN_workflow_summary.md"
content: "[Generated from template above]"
cross_references:
  - update_plan: add_summary_reference
  - update_reports: add_summary_reference
```

**Cross-Reference Updates**:
```markdown
Update related files to link back to summary:

In Implementation Plan (specs/plans/NNN_*.md):
Add at bottom:
## Implementation Summary
This plan was executed on [date]. See workflow summary:
- [Summary path and link]

In Research Reports (if any):
Add in relevant section:
### Implementation Reference
Findings from this report were incorporated into:
- [Plan path] - Implementation plan
- [Summary path] - Workflow execution summary
```

#### Step 7: Save Final Checkpoint

**Workflow Complete Checkpoint**:
```yaml
checkpoint_workflow_complete:
  phase_name: "documentation"
  completion_time: [timestamp]
  outputs:
    documentation_updated: [list of files]
    summary_created: "specs/summaries/NNN_*.md"
    cross_references: [count]
    status: "success"
  next_phase: "complete"

  final_metrics:
    total_workflow_time: "[duration]"
    phases_completed: [list]
    artifacts_generated: [count]
    files_modified: [count]
    error_recovery_success: "[%]"

  workflow_summary:
    research_reports: [list]
    implementation_plan: "[path]"
    workflow_summary: "[path]"
    tests_passing: true
```

#### Step 8: Create Pull Request (Optional)

**When to Create PR:**
- If `--create-pr` flag is provided, OR
- If project CLAUDE.md has GitHub Integration configured with auto-PR for branch pattern

**Prerequisites Check:**
Before invoking github-specialist agent:
```bash
# Check if gh CLI is available and authenticated
if ! command -v gh &>/dev/null; then
  echo "Note: gh CLI not installed. Skipping PR creation."
  echo "Install: brew install gh (or equivalent)"
  exit 0
fi

if ! gh auth status &>/dev/null; then
  echo "Note: gh CLI not authenticated. Skipping PR creation."
  echo "Run: gh auth login"
  exit 0
fi
```

**Invoke github-specialist Agent:**

Use Task tool with behavioral injection:

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Create PR for completed workflow using github-specialist protocol"
  prompt: |
    Read and follow the behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/github-specialist.md

    You are acting as a GitHub Specialist Agent with the tools and constraints
    defined in that file.

    Create Pull Request for Workflow:
    - Plan: [absolute path to implementation plan]
    - Branch: [current branch name from git]
    - Base: main (or master, detect from repo)
    - Summary: [absolute path to workflow summary]

    PR Description Should Include:
    - Workflow overview from summary file
    - Research phase: N reports generated with key findings
    - Implementation: All N phases completed successfully
    - Test results: All passing (or fixed after M debug iterations)
    - Documentation: N files updated
    - Performance metrics: Time saved via parallelization
    - File changes summary from git diff --stat

    Follow comprehensive PR template structure from github-specialist agent.
    This is a workflow PR, so include cross-references to all artifacts:
    - Research reports (if any)
    - Implementation plan
    - Workflow summary
    - Debug reports (if debugging occurred)

    Output: PR URL and number for user
}
```

**Capture PR URL:**
After agent completes:
- Extract PR URL from agent output
- Update workflow summary with PR link
- Update plan file Implementation Summary section with PR link

**Example Update to Summary:**
```markdown
## Pull Request
- **PR**: https://github.com/user/repo/pull/123
- **Created**: [YYYY-MM-DD]
- **Status**: Open
```

**Graceful Degradation:**
If PR creation fails:
- Log the error from agent
- Provide manual gh pr create command
- Continue without blocking (workflow is complete)
- Summary file still valid without PR link

**Example Manual Command:**
```bash
gh pr create \
  --title "feat: [feature name from workflow]" \
  --body "$(cat pr_description.txt)" \
  --base main
```

#### Step 9: Workflow Completion Message

**Final Output to User**:
```markdown
✅ Workflow Complete

**Duration**: [HH:MM:SS]

**Artifacts Generated**:
[If research]
- Research reports: N ([paths])
- Implementation plan: [path]
- Workflow summary: [path]
- Documentation updates: N files
[If PR created]
- Pull Request: [PR URL]

**Implementation Results**:
- Files modified: N
- Tests: ✓ All passing
[If debugging occurred]
- Issues resolved: N (after M debug iterations)

**Performance**:
- Time saved via parallelization: [N%]
- Error recovery: [N/M errors auto-recovered]

**Summary**: [summary_path]

Review the workflow summary for complete details, cross-references, and lessons learned.
```

#### Documentation Phase Example

```markdown
User Request: "Add user authentication with email and password"

Workflow Phases Completed:
✓ Research (3 parallel agents, 5min)
✓ Planning (created specs/plans/013_auth_implementation.md, 3min)
✓ Implementation (4 phases, all tests passing, 25min)
✓ Documentation (updated 3 files, created summary, 4min)

Total Duration: 37 minutes

Documentation Updated:
- nvim/README.md (added auth section)
- nvim/docs/ARCHITECTURE.md (added auth module diagram)
- nvim/lua/neotex/auth/README.md (created)

Workflow Summary Created:
- specs/summaries/013_auth_workflow_summary.md
- Cross-referenced: 2 research reports, 1 plan, 3 updated docs

Performance Metrics:
- Parallel research saved ~8 minutes (estimated)
- Zero errors, no debugging needed
- All cross-references verified

Checkpoint Saved: workflow_complete
Status: ✅ Success
```

---

## Orchestration Workflow Complete

**CHECKPOINT REQUIREMENT - Report Workflow Completion**

After documentation phase completes, YOU MUST report this final checkpoint:

```
═══════════════════════════════════════════════════════
CHECKPOINT: Orchestration Workflow Complete
═══════════════════════════════════════════════════════

Workflow Status: COMPLETE ✓

Workflow Summary:
- Original request: $WORKFLOW_DESCRIPTION
- Total duration: [calculated]
- Phases executed: 4 (Research, Planning, Implementation, Documentation)

Artifacts Created:
- Research reports: ${#RESEARCH_REPORT_PATHS[@]}
- Implementation plan: $IMPLEMENTATION_PLAN_PATH
- Implementation commits: $GIT_COMMITS
- Workflow summary: $SUMMARY_PATH

Implementation Results:
- Tests passing: $TESTS_PASSING
- Files modified: $FILES_MODIFIED
- Phases completed: $PHASES_COMPLETED
- Implementation success: $IMPLEMENTATION_SUCCESS

Performance Metrics:
- Research time: [duration]
- Planning time: [duration]
- Implementation time: [duration]
- Documentation time: [duration]
- Total workflow time: [duration]
- Parallel execution savings: ~60-70% (research phase)

Context Usage:
- Research phase: <10% (metadata only)
- Planning phase: <20%
- Implementation phase: variable
- Documentation phase: <10%
- Overall: <30% average

Next Steps:
- Review workflow summary: $SUMMARY_PATH
- Review implementation plan: $IMPLEMENTATION_PLAN_PATH
- Review research reports: ${#RESEARCH_REPORT_PATHS[@]} files
═══════════════════════════════════════════════════════
```

**CRITICAL**: This checkpoint is MANDATORY. It marks the official completion of the orchestration workflow.

---

## Context Management Strategy

### Orchestrator Context (Minimal - <30% usage)

I maintain only:
- Current workflow state (phase, completion status)
- Checkpoint data (success/failure per phase)
- High-level summaries (research: 200 words max)
- File paths (not content): plan path, modified files, doc paths
- Error history: what failed, what recovery action taken
- Performance metrics: phase times, parallel effectiveness

### Subagent Context (Comprehensive)

Each subagent receives:
- Complete task description with clear objective
- Necessary context from prior phases (summaries only)
- Project standards reference (CLAUDE.md)
- Explicit success criteria
- Expected output format
- Error handling guidance

**No routing logic or orchestration details passed to subagents.**

### Context Passing Protocol

```markdown
For each subagent invocation:
1. Extract minimal necessary context from prior phases
2. Structure as focused task description
3. Remove all orchestration routing logic
4. Include explicit success criteria
5. Specify exact output format
```

## Error Recovery Mechanism

### Error Classification

**Error Types**:
1. **Timeout Errors**: Agent execution exceeds time limits
2. **Tool Access Errors**: Permission or availability issues
3. **Validation Failures**: Output doesn't meet criteria
4. **Test Failures**: Code tests fail (handled by Debugging Loop)
5. **Integration Errors**: Command invocation failures
6. **Context Overflow**: Orchestrator context approaches limits

### Automatic Recovery Strategies

See [Error Recovery Patterns](../docs/command-patterns.md#error-recovery-patterns) for detailed recovery strategies including:
- Automatic Retry with Backoff
- Error Classification and Routing (timeout, tool access, validation, integration)
- User Escalation Format

**Orchestrate-specific recovery**:
- Context Overflow Prevention: Compress context, summarize aggressively, reduce workflow scope
- Checkpoint-based recovery: Rollback to last successful phase
- Error history tracking: Learn from failures to improve future workflows

### Checkpoint Recovery System

See [Checkpoint Management Patterns](../docs/command-patterns.md#checkpoint-management-patterns) for checkpoint creation and restoration.

**Orchestrate-specific checkpoints**:
- Stored in orchestrator memory (minimal, ephemeral)
- Used for in-session recovery only
- Enable rollback to previous successful phase
- Preserve partial work on failures

### Manual Intervention Points

#### When to Escalate

**Automatic Escalation Triggers**:
1. **Max retries exceeded** (3 attempts for most error types)
2. **Critical failures** (data loss, security issues)
3. **Debugging loop limit** (3 debugging iterations)
4. **Context overflow** (compression limit reached)
5. **Architectural decisions** (user input required)

#### Escalation Format

See [User Escalation Format](../docs/command-patterns.md#pattern-user-escalation-format) for standard escalation message structure.

**User Options**:
- `continue`: Resume with manual fixes
- `retry [phase]`: Retry specific phase
- `rollback [phase]`: Return to checkpoint
- `terminate`: End workflow gracefully
- `debug`: Enter manual debugging mode

## Performance Monitoring

### Metrics Collection

Track throughout workflow:
- **Phase Execution Times**: Time per phase
- **Parallelization Effectiveness**: Actual vs potential time savings
- **Error Rates**: Failures per phase
- **Context Window Utilization**: Orchestrator context usage
- **Recovery Success**: Automatic vs manual interventions

### Optimization Recommendations

After workflow completion, suggest:
- Which phases could benefit from parallelization
- Bottleneck phases for optimization
- Checkpoint placement improvements
- Context management refinements

## Execution Flow

### Initial Workflow Processing

When invoked with `<workflow-description>`:

1. **Parse and Classify**:
   - Extract feature/task description
   - Determine workflow type
   - Identify complexity level
   - Check for parallel/sequential flags

2. **Initialize TodoWrite**:
   ```markdown
   Create todo list with identified phases:
   - [ ] Research phase (if needed)
   - [ ] Planning phase
   - [ ] Implementation phase
   - [ ] Debugging loop (conditional)
   - [ ] Documentation phase
   ```

3. **Execute Phases Sequentially**:
   - Research (parallel subagents) → synthesize
   - Planning (single subagent) → extract plan path
   - Implementation (single subagent) → check tests
   - Debugging (conditional loop) → ensure tests pass
   - Documentation (single subagent) → generate summary

4. **Update TodoWrite** after each phase completion

5. **Generate Final Summary**:
   - Workflow completion report
   - Performance metrics
   - Cross-references to all generated documents

## Usage Examples

### Example 1: Simple Feature (No Research)

```
/orchestrate Add hello world function
```

**Expected Execution**:
- Skip research (simple feature)
- Plan: plan-architect creates implementation plan
- Implement: code-writer executes plan
- Document: doc-writer updates documentation

**Duration**: ~5 minutes
**Agents Invoked**: 3 (plan-architect, code-writer, doc-writer)

**Artifacts Generated**:
- `specs/plans/NNN_hello_world.md` - Implementation plan
- `[source_file]` - Source file containing hello world function
- `specs/summaries/NNN_hello_world_summary.md` - Workflow summary

### Example 2: Medium Feature (With Research)

```
/orchestrate Add configuration validation module
```

**Expected Execution**:
- Research: 2-3 parallel research-specialist agents investigate patterns and practices
- Plan: plan-architect synthesizes research into implementation plan
- Implement: code-writer executes plan
- Document: doc-writer updates documentation

**Duration**: ~15 minutes
**Agents Invoked**: 5-6 (2-3 research-specialist, plan-architect, code-writer, doc-writer)

**Artifacts Generated**:
- `specs/reports/existing_patterns/001_config_patterns.md` - Research report #1
- `specs/reports/best_practices/001_validation_practices.md` - Research report #2
- `specs/plans/NNN_config_validation.md` - Implementation plan referencing reports
- `[source_files]` - Validation module implementation
- `specs/summaries/NNN_config_validation_summary.md` - Workflow summary

### Example 3: Complex Feature (With Debugging)

```
/orchestrate Add authentication middleware with session management
```

**Expected Execution**:
- Research: 2 parallel research-specialist agents
- Plan: plan-architect creates comprehensive plan
- Implement: code-writer executes plan (possible test failures initially)
- Debug: debug-specialist investigates failures, code-writer applies fixes (1-3 iterations)
- Document: doc-writer updates documentation

**Duration**: ~30-45 minutes
**Agents Invoked**: 6-8 (2 research-specialist, plan-architect, code-writer, 1-2 debug-specialist, 1-2 code-writer for fixes, doc-writer)

**Artifacts Generated**:
- `specs/reports/auth_patterns/001_auth_research.md`
- `specs/reports/security_practices/001_security_research.md`
- `specs/plans/NNN_authentication_middleware.md`
- `debug/phase2_failures/001_missing_dependency.md` - Debug report (if needed)
- `[source_files]` - Authentication middleware implementation
- `specs/summaries/NNN_authentication_summary.md`

### Example 4: Workflow with Escalation

```
/orchestrate Implement payment processing with external API integration
```

**Expected Execution**:
- Research: 3 parallel research-specialist agents
- Plan: plan-architect creates plan
- Implement: code-writer attempts implementation
- Debug: 3 iterations of debug-specialist + code-writer (all fail)
- Escalation: User receives actionable message with checkpoint

**Duration**: ~20 minutes (escalated before completion)
**Agents Invoked**: 9-10 (3 research-specialist, plan-architect, code-writer, 3 debug-specialist, 3 code-writer for fixes)

**Artifacts Generated**:
- `specs/reports/payment_apis/001_api_research.md`
- `specs/reports/integration_patterns/001_integration_research.md`
- `specs/reports/security/001_security_research.md`
- `specs/plans/NNN_payment_processing.md`
- `debug/integration_issues/001_api_connection_failed.md` - Debug report iteration 1
- `debug/integration_issues/002_authentication_error.md` - Debug report iteration 2
- `debug/integration_issues/003_missing_credentials.md` - Debug report iteration 3
- `[source_files]` - Partial payment implementation
- **NO summary file** (workflow escalated before documentation phase)

**Escalation Checkpoint**: `.claude/checkpoints/orchestrate_payment_processing.json`

## Notes

### Architecture Principles

**Supervisor Pattern** (LangChain 2025):
- Centralized coordination with minimal state
- Specialized subagents with focused tasks
- Context isolation prevents cross-contamination
- Forward message pattern avoids paraphrasing errors

**Context Preservation**:
- Orchestrator: <30% context usage (state, checkpoints, summaries only)
- Subagents: Comprehensive context for their specific task
- No routing logic passed to workers
- Structured handoffs with explicit success criteria

**Error Recovery**:
- Multi-level detection (timeout, tool access, validation)
- Automatic retry with adjusted parameters
- Checkpoint-based rollback and resume
- Graceful degradation to sequential execution

### When to Use /orchestrate

**Use /orchestrate for**:
- Complex multi-phase workflows (≥3 phases)
- Features requiring research + planning + implementation
- Tasks benefiting from parallel execution
- Workflows needing systematic error recovery

**Use individual commands for**:
- Simple single-phase tasks
- Direct implementation without planning
- Quick documentation updates
- Straightforward bug fixes

### Implementation Status

**Full implementation complete!** All phases have been implemented:

- [x] Phase 1: Foundation and Command Structure
- [x] Phase 2: Research Phase Coordination
- [x] Phase 3: Planning and Implementation Phase Integration
- [x] Phase 4: Error Recovery and Debugging Loop
- [x] Phase 5: Documentation Phase and Workflow Completion

The /orchestrate command provides comprehensive multi-agent workflow coordination with:
- Parallel research execution with context minimization
- Direct agent invocation via Behavioral Injection Pattern (plan-architect, code-writer, debug-specialist, doc-writer)
- Robust error recovery with automatic retry strategies
- Intelligent debugging loop with 3-iteration limit
- Complete documentation generation with cross-referencing
- Checkpoint-based recovery system
- Performance metrics tracking

Ready to orchestrate end-to-end development workflows!

## Agent Usage

This command uses specialized agents for each workflow phase:

### Research Phase
- **Agent**: `research-specialist` (multiple instances in parallel)
- **Purpose**: Codebase analysis, best practices research, alternative approaches
- **Tools**: Read, Grep, Glob, WebSearch, WebFetch
- **Invocation**: 2-4 parallel agents depending on workflow complexity

### Planning Phase
- **Agent**: `plan-architect`
- **Purpose**: Generate structured implementation plans from research findings
- **Tools**: Read, Write, Grep, Glob, WebSearch
- **Invocation**: Single agent, sequential execution

### Implementation Phase
- **Agent**: `code-writer`
- **Purpose**: Execute implementation plans phase by phase with testing
- **Tools**: Read, Write, Edit, Bash, TodoWrite
- **Invocation**: Single agent with extended timeout for complex implementations

### Debugging Loop (Conditional)
- **Investigation**: `debug-specialist`
  - Purpose: Root cause analysis and diagnostic reporting
  - Tools: Read, Bash, Grep, Glob, WebSearch
- **Fix Application**: `code-writer`
  - Purpose: Apply proposed fixes from debug reports
  - Tools: Read, Write, Edit, Bash, TodoWrite
- **Invocation**: Up to 3 debugging iterations before escalation

### Documentation Phase
- **Agent**: `doc-writer`
- **Purpose**: Update documentation and generate workflow summaries
- **Tools**: Read, Write, Edit, Grep, Glob
- **Invocation**: Single agent, sequential execution

#### Plan Hierarchy Update in Documentation Phase

After implementation completes successfully, update plan hierarchy to ensure all parent/grandparent plan files reflect completion status.

**When to Update**:
- After implementation phase completes (all tests passing)
- Before generating workflow summary
- For all expanded plan hierarchies (Level 1 and Level 2)

**Update Workflow**:

1. **Determine Plan Structure**:
   ```bash
   # Check if implementation created an expanded plan
   PLAN_PATH=$(get_plan_path_from_implementation_phase)
   STRUCTURE_LEVEL=$(detect_structure_level "$PLAN_PATH")
   ```

2. **Invoke Spec-Updater Agent** (if expanded):
   ```
   Task {
     subagent_type: "general-purpose"
     description: "Update plan hierarchy after workflow completion"
     prompt: |
       Read and follow the behavioral guidelines from:
       /home/benjamin/.config/.claude/agents/spec-updater.md

       You are acting as a Spec Updater Agent.

       Update plan hierarchy for completed workflow.

       Plan: ${PLAN_PATH}
       All phases have been completed successfully.

       Steps:
       1. Source checkbox utilities: source .claude/lib/checkbox-utils.sh
       2. Detect structure level: detect_structure_level "${PLAN_PATH}"
       3. For each completed phase: mark_phase_complete "${PLAN_PATH}" ${phase_num}
       4. Verify consistency: verify_checkbox_consistency "${PLAN_PATH}" (all phases)
       5. Report: List all files updated across hierarchy

       Expected output:
       - Confirmation of hierarchy update
       - List of all updated files (stage → phase → main plan)
       - Verification that all levels are synchronized
   }
   ```

3. **Validate Update Success**:
   - Check agent response for successful completion
   - Verify all hierarchy levels updated (if applicable)
   - Confirm no consistency errors reported

4. **Include in Workflow Summary**:
   Add hierarchy update confirmation to workflow summary:
   ```markdown
   ## Plan Hierarchy Status
   - Structure Level: [0|1|2]
   - All parent plans synchronized: [Yes|No]
   - Files updated: [list of plan files updated]
   ```

**Error Handling**:
- If hierarchy update fails: Log warning but continue with summary generation
- User notified in workflow summary that manual sync is required
- Link to checkbox-utils.sh for manual synchronization

**Skip Conditions**:
- Level 0 plans (single file) - no hierarchy to update
- Plans not using progressive expansion
- Implementation phase did not use code-writer agent with behavioral injection


### Agent Integration Benefits
- **Specialized Expertise**: Each agent optimized for its specific task
- **Tool Restrictions**: Security through limited tool access per agent
- **Parallel Execution**: Research-specialist agents run concurrently
- **Context Isolation**: Agents receive only relevant context for their phase
- **Clear Responsibilities**: No ambiguity about which agent handles what

## Checkpoint Detection and Resume

Before starting the workflow, YOU MUST check for existing checkpoints that might indicate an interrupted workflow.

### Step 1: Check for Existing Checkpoint

```bash
# Load most recent orchestrate checkpoint
CHECKPOINT=$(.claude/lib/load-checkpoint.sh orchestrate 2>/dev/null || echo "")
```

### Step 2: Interactive Resume Prompt (if checkpoint found)

If a checkpoint exists, YOU MUST present interactive options:

```
Found existing checkpoint for orchestrate workflow
Project: [project_name]
Created: [created_at] ([age] ago)
Progress: Phase [current_phase] of [total_phases] completed
Status: [status]

Options:
  (r)esume - Continue from Phase [current_phase + 1]
  (s)tart fresh - Delete checkpoint and restart workflow
  (v)iew details - Show checkpoint contents
  (d)elete - Remove checkpoint without starting

Choice [r/s/v/d]:
```

### Step 3: Resume Workflow State (if user chooses resume)

If user selects resume:
1. Load `workflow_state` from checkpoint
2. Restore `project_name`, `research_reports`, `completed_phases`
3. Skip to next incomplete phase
4. Continue workflow from that point

### Step 4: Save Checkpoints at Key Milestones

Throughout workflow execution, save checkpoints after each major phase:

```bash
# After research phase
.claude/lib/save-checkpoint.sh orchestrate "$PROJECT_NAME" "$WORKFLOW_STATE_JSON"

# After planning phase
.claude/lib/save-checkpoint.sh orchestrate "$PROJECT_NAME" "$UPDATED_STATE_JSON"

# After implementation phase
.claude/lib/save-checkpoint.sh orchestrate "$PROJECT_NAME" "$UPDATED_STATE_JSON"

# After debugging (if needed)
.claude/lib/save-checkpoint.sh orchestrate "$PROJECT_NAME" "$UPDATED_STATE_JSON"
```

### Step 5: Cleanup on Completion

On successful workflow completion:
```bash
# Delete checkpoint file
rm .claude/data/checkpoints/orchestrate_${PROJECT_NAME}_*.json
```

On workflow failure:
```bash
# Archive checkpoint to failed/ directory
mv .claude/data/checkpoints/orchestrate_${PROJECT_NAME}_*.json .claude/data/checkpoints/failed/
```

Let me begin orchestrating your workflow based on the description provided.
