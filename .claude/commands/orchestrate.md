---
allowed-tools: Task, TodoWrite, Read, Write, Bash, Grep, Glob
argument-hint: <workflow-description> [--parallel] [--sequential] [--create-pr] [--dry-run]
description: Coordinate subagents through end-to-end development workflows
command-type: primary
dependent-commands: report, plan, implement, debug, test, document, github-specialist
---

# Multi-Agent Workflow Orchestration

I'll coordinate multiple specialized subagents through a complete development workflow, from research to documentation, while preserving context and enabling intelligent parallelization.

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

**Preview Output Example**:
```
┌─────────────────────────────────────────────────────────────┐
│ Workflow: Add user authentication with JWT tokens (Dry-Run)│
├─────────────────────────────────────────────────────────────┤
│ Workflow Type: feature  |  Estimated Duration: ~28 minutes  │
│ Complexity: Medium-High  |  Agents Required: 6              │
├─────────────────────────────────────────────────────────────┤
│ Phase 1: Research (Parallel - 3 agents)           ~8min    │
│   ├─ research-specialist: "JWT authentication patterns"    │
│   │    Report: specs/reports/jwt_patterns/001_*.md         │
│   ├─ research-specialist: "Security best practices"        │
│   │    Report: specs/reports/security/001_*.md             │
│   └─ research-specialist: "Token refresh strategies"       │
│        Report: specs/reports/token_refresh/001_*.md        │
│                                                              │
│ Phase 2: Planning (Sequential)                    ~5min    │
│   └─ plan-architect: Synthesize research into plan         │
│        Plan: specs/plans/NNN_user_authentication.md        │
│        Uses: 3 research reports                             │
│                                                              │
│ Phase 3: Implementation (Adaptive)                ~12min   │
│   └─ code-writer: Execute plan phase-by-phase              │
│        Files: auth/, middleware/, utils/                    │
│        Tests: test_auth.lua, test_jwt.lua                   │
│        Phases: 4 (1 sequential, 1 parallel wave)           │
│                                                              │
│ Phase 4: Debugging (Conditional)                  ~0min    │
│   └─ debug-specialist: Skipped (no test failures)          │
│        Triggers: Only if implementation tests fail          │
│        Max iterations: 3                                    │
│                                                              │
│ Phase 5: Documentation (Sequential)               ~3min    │
│   └─ doc-writer: Update docs and generate summary          │
│        Files: README.md, CHANGELOG.md, API.md               │
│        Summary: specs/summaries/NNN_*.md                    │
├─────────────────────────────────────────────────────────────┤
│ Execution Summary:                                           │
│   Total Phases: 5  |  Conditional Phases: 1  |  Parallel: Yes│
│   Agents Invoked: 6  |  Reports: 3  |  Plans: 1            │
│   Files Created: ~12  |  Tests: ~5                          │
│   Estimated Time: 28 minutes (20min with parallelism)      │
└─────────────────────────────────────────────────────────────┘

Proceed with workflow execution? (y/n):
```

**Workflow Type Detection**:
- **feature**: Adding new functionality (triggers full workflow)
- **refactor**: Code restructuring (skips research if standards exist)
- **debug**: Investigation and fixes (starts with debug phase)
- **investigation**: Research-only (skips implementation)

**Use Cases**:
- **Validation**: Verify workflow interpretation before execution
- **Time estimation**: Understand time commitment for complete workflow
- **Resource planning**: See which agents will be involved
- **Scope verification**: Confirm research topics and implementation scope
- **Team coordination**: Share workflow plan before starting
- **Budget estimation**: Understand LLM API costs based on agent count

**Dry-Run Scope**:
- ✓ Analyzes workflow description
- ✓ Identifies research topics
- ✓ Determines agent assignments
- ✓ Estimates phase durations
- ✓ Shows execution order and parallelism
- ✓ Lists artifacts to be created
- ✗ Does not invoke agents
- ✗ Does not create files
- ✗ Does not execute commands
- ✗ Does not create reports/plans

**Dry-Run with Other Flags**:
```bash
# Dry-run with parallel research (default)
/orchestrate "Add feature X" --dry-run

# Dry-run with sequential research
/orchestrate "Add feature X" --dry-run --sequential

# Dry-run with PR creation enabled
/orchestrate "Add feature X" --dry-run --create-pr
```

**Implementation Details**:
- Workflow analysis uses pattern matching and keyword detection
- Duration estimation from `.claude/lib/agent-registry-utils.sh` metrics
- Research topic extraction via semantic analysis of workflow description
- Agent selection based on workflow type and phase requirements

## Workflow Analysis

Let me first analyze your workflow description to identify the natural phases and requirements.

## Workflow Execution Infrastructure

Before beginning the workflow, I'll initialize the execution infrastructure for progress tracking, state management, and checkpoint persistence.

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
[ -f "$UTILS_DIR/error-utils.sh" ] || { echo "ERROR: error-utils.sh not found"; exit 1; }
[ -f "$UTILS_DIR/checkpoint-utils.sh" ] || { echo "ERROR: checkpoint-utils.sh not found"; exit 1; }

# Source utilities
source "$UTILS_DIR/error-utils.sh"
source "$UTILS_DIR/checkpoint-utils.sh"

echo "✓ Shared utilities initialized"
```

**Available Utilities**:
- **Checkpoint Management**: `.claude/lib/checkpoint-utils.sh` for saving/restoring workflow state
- **Error Handling**: `.claude/lib/error-utils.sh` for agent error recovery and fallback strategies
  - `retry_with_backoff()`: Automatic retry with exponential backoff
  - `classify_error()`: Categorize error types
  - `suggest_recovery()`: Generate recovery suggestions
  - `format_error_report()`: Structured error reporting

These utilities ensure workflow state is preserved across interruptions and agent failures are handled gracefully.

## Error Handling Strategy

Throughout the workflow, handle errors according to these principles:

### Agent Invocation Failures

**Use error-utils.sh for systematic retry and recovery**:

**Step 1: Wrap Agent Invocation with retry_with_backoff()**
```bash
source "$CLAUDE_PROJECT_DIR/.claude/lib/error-utils.sh"

# Define the agent invocation command
invoke_agent() {
  # Invoke Task tool with agent parameters
  # Returns 0 on success, non-zero on failure
}

# Use retry_with_backoff for automatic retry with exponential backoff
AGENT_RESULT=$(retry_with_backoff invoke_agent "research_agent_invocation")
RETRY_STATUS=$?
```

**Step 2: Handle Retry Outcomes**
```bash
if [ $RETRY_STATUS -eq 0 ]; then
  # Agent invocation succeeded (possibly after retries)
  echo "✓ Agent invocation successful"
else
  # All retries exhausted, classify and handle error
  ERROR_TYPE=$(classify_error "$AGENT_RESULT")
  ERROR_REPORT=$(format_error_report "$ERROR_TYPE" "$AGENT_RESULT" "$CURRENT_PHASE")

  # Log to workflow_state.execution_tracking.error_history
  echo "$ERROR_REPORT"

  # Save checkpoint and escalate to user
  save_workflow_checkpoint
fi
```

**Step 3: Validate Agent Output**
```bash
# If agent completes but returns error content
if grep -q "ERROR" "$AGENT_OUTPUT"; then
  # Classify the error type
  ERROR_TYPE=$(classify_error "$AGENT_OUTPUT")

  # Get recovery suggestions
  SUGGESTIONS=$(suggest_recovery "$ERROR_TYPE" "$AGENT_OUTPUT")

  # Decide recovery action based on error type
  case "$ERROR_TYPE" in
    "file_not_found"|"import_error")
      # Recoverable - correct context and retry
      retry_with_backoff invoke_agent_with_corrected_context
      ;;
    *)
      # Not recoverable - escalate
      format_error_report "$ERROR_TYPE" "$AGENT_OUTPUT" "$CURRENT_PHASE"
      save_checkpoint_and_escalate
      ;;
  esac
fi
```

**Benefits**:
- Exponential backoff prevents overwhelming failed services
- Automatic retry reduces transient failures
- Consistent error classification and reporting
- Logged retry attempts for debugging

### File Creation Failures

**Use error-utils.sh for file creation verification and retry**:

```bash
# Define file verification function
verify_file_created() {
  local expected_path="$1"
  [ -f "$expected_path" ] && return 0 || return 1
}

# Retry file creation with backoff
if ! retry_with_backoff "verify_file_created $EXPECTED_FILE_PATH"; then
  # File still missing after retries
  ERROR_TYPE="file_not_found"
  ERROR_MSG="Expected file not created: $EXPECTED_FILE_PATH"

  # Classify and format error
  ERROR_REPORT=$(format_error_report "$ERROR_TYPE" "$ERROR_MSG" "$CURRENT_PHASE")
  echo "$ERROR_REPORT"

  # Get recovery suggestions
  SUGGESTIONS=$(suggest_recovery "$ERROR_TYPE" "$ERROR_MSG")
  echo "Recovery options:"
  echo "$SUGGESTIONS"

  # Save checkpoint and escalate
  save_checkpoint_and_escalate
fi
```

### Test Failures

**Test failures are expected** - handle via debugging loop:
1. DO NOT treat test failures as errors
2. ENTER debugging loop (max 3 iterations)
3. ONLY escalate if debugging loop exhausted

### Checkpoint Failures

**Use checkpoint-utils.sh with automatic retry**:

```bash
source "$CLAUDE_PROJECT_DIR/.claude/lib/checkpoint-utils.sh"

# Save checkpoint with automatic retry
if ! save_checkpoint "orchestrate" "$CHECKPOINT_DATA"; then
  # Save failed after retries
  echo "⚠ Warning: Checkpoint save failed"
  echo "Workflow will continue, but resume may not be possible"
  echo "This will be noted in the final summary"

  # Log failure but don't block workflow
  log_error "checkpoint_save_failed" "orchestrate" "$CURRENT_PHASE"

  # Continue execution (checkpoint is not critical)
fi
```

**Graceful degradation**:
- Checkpoint failures don't block workflow execution
- User warned that resume won't be possible
- Failure logged for debugging
- Workflow continues normally
- Limitation documented in summary

### General Error Recovery

```yaml
error_recovery_pattern:
  1_capture: Record full error message and context
  2_classify: Determine if error is transient or permanent
  3_retry: Attempt recovery once if transient
  4_log: Add to workflow_state.execution_tracking.error_history
  5_escalate: Provide user with clear options (resume, manual intervention, abort)
```

### Error History Structure

```yaml
workflow_state.execution_tracking.error_history:
  - phase: "research"
    error_type: "agent_invocation_failure"
    error_message: "Task tool timeout after 600s"
    recovery_attempted: "Retry invocation"
    recovery_success: false
    escalated_to_user: true
    timestamp: "2025-10-12T14:30:22"
```

## Progress Streaming

Throughout the workflow, emit progress markers to provide real-time visibility into execution status.

### Progress Marker Format

USE `PROGRESS:` prefix for all progress messages:

```
PROGRESS: [phase] - [action_description]
```

### When to Emit Progress Markers

**At Phase Transitions**:
```
PROGRESS: Starting Research Phase (parallel execution)
PROGRESS: Research Phase complete - 3 reports created
PROGRESS: Starting Planning Phase (sequential execution)
PROGRESS: Planning Phase complete - plan created
PROGRESS: Starting Implementation Phase (adaptive execution)
PROGRESS: Implementation Phase complete - tests passing
PROGRESS: Starting Documentation Phase (sequential execution)
PROGRESS: Documentation Phase complete - workflow summary generated
```

**During Agent Invocations**:
```
PROGRESS: Invoking 3 research-specialist agents in parallel...
PROGRESS: Research agent 1/3 completed (existing_patterns)
PROGRESS: Research agent 2/3 completed (security_practices)
PROGRESS: Research agent 3/3 completed (framework_implementations)

PROGRESS: Invoking plan-architect agent...
PROGRESS: Plan created: specs/plans/042_user_authentication.md

PROGRESS: Invoking code-writer agent with /implement...
PROGRESS: Implementation Phase 1/4 complete
PROGRESS: Implementation Phase 2/4 complete
PROGRESS: Implementation Phase 3/4 complete
PROGRESS: Implementation Phase 4/4 complete - tests passing

PROGRESS: Invoking doc-writer agent for workflow summary...
PROGRESS: Workflow summary created: specs/summaries/042_summary.md
```

**During Debugging Loop**:
```
PROGRESS: Entering debugging loop (iteration 1/3)
PROGRESS: Invoking debug-specialist agent...
PROGRESS: Debug report created: debug/test_failures/001_auth_timeout.md
PROGRESS: Applying recommended fix via code-writer agent...
PROGRESS: Fix applied - running tests...
PROGRESS: Tests passing ✓ - debugging complete
```

**During File Operations**:
```
PROGRESS: Saving research checkpoint...
PROGRESS: Checkpoint saved: .claude/checkpoints/orchestrate_user_auth_20251012_143022.json

PROGRESS: Verifying report files created...
PROGRESS: All 3 reports verified and readable
```

**During Cross-Reference Creation**:
```
PROGRESS: Creating bidirectional cross-references...
PROGRESS: Plan → Reports links added (3 links)
PROGRESS: Reports → Plan links added (3 links)
PROGRESS: Summary → All artifacts links added (7 links)
PROGRESS: Cross-reference validation complete
```

### Progress Streaming Best Practices

1. **Emit Before Long Operations**: Always emit before agent invocations, file reads, or bash operations
2. **Include Context**: Specify which phase/agent/file is being processed
3. **Show Counts**: Use "N/M" format for multi-step operations
4. **Indicate Success**: Use ✓ for successful completions
5. **Update TodoWrite**: Emit progress after updating TodoWrite status

### Progress + TodoWrite Coordination

ALWAYS update TodoWrite BEFORE emitting phase transition progress marker:

```
1. Update TodoWrite (mark current phase complete, next phase in_progress)
2. Emit PROGRESS: marker
3. Proceed with next phase
```

**Example**:
```
[Update TodoWrite: research → completed, planning → in_progress]
PROGRESS: Research Phase complete - 3 reports created
PROGRESS: Starting Planning Phase (sequential execution)
[Invoke plan-architect agent]
```

### Progress Marker Density

**Appropriate Density**:
- Phase transitions: Always
- Agent invocations: Always
- Long-running operations (>30s): Every 30s or at natural checkpoints
- File operations: For important files (plans, reports, summaries)
- Verification steps: At completion

**Avoid Over-Emitting**:
- Internal state updates (don't emit for every workflow_state change)
- Trivial operations (string formatting, variable assignment)
- Repeated operations (don't emit for each of 100 files read)

### Step 1: Parse Workflow Description

I'll extract:
- **Core Feature/Task**: What needs to be accomplished
- **Workflow Type**: Feature development, refactoring, debugging, or investigation
- **Complexity Indicators**: Keywords suggesting scope and approach
- **Parallelization Hints**: Tasks that can run concurrently

### Step 2: Identify Workflow Phases

Based on the description, I'll determine which phases are needed:

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

I'll create minimal orchestrator state:

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

### Research Phase (Parallel Execution)

#### Step 1: Identify Research Topics

ANALYZE the workflow description to extract 2-4 focused research topics.

**EXECUTE NOW**:

1. READ the user's workflow description from the /orchestrate invocation
2. IDENTIFY key areas requiring investigation:
   - Existing implementations in codebase
   - Industry best practices and standards
   - Alternative approaches and trade-offs
   - Technical constraints and requirements
3. EXTRACT 2-4 specific topics based on workflow complexity
4. GENERATE topic titles for each research area

**Topic Categories** (use as guidance):
- **existing_patterns**: Current codebase implementations and patterns
- **best_practices**: Industry standards for the technology/approach
- **alternatives**: Alternative implementations and their trade-offs
- **constraints**: Technical limitations, requirements, security considerations

**Complexity-Based Research Strategy**:
```yaml
Simple Workflows (skip research):
  - Keywords: "fix", "update", "small change"
  - Action: Skip directly to planning phase
  - Thinking Mode: None (standard processing)

Medium Workflows (focused research):
  - Keywords: "add", "improve", "refactor"
  - Topics: 2-3 focused areas
  - Example: existing patterns + best practices
  - Thinking Mode: "think" (moderate complexity)

Complex Workflows (comprehensive research):
  - Keywords: "implement", "redesign", "architecture"
  - Topics: 3-4 comprehensive areas
  - Example: patterns + practices + alternatives + constraints
  - Thinking Mode: "think hard" (high complexity)

Critical Workflows (system-wide impact):
  - Keywords: "security", "breaking change", "core refactor"
  - Topics: 4+ comprehensive areas
  - Thinking Mode: "think harder" (critical decisions)
```

#### Step 1.5: Determine Thinking Mode

CALCULATE workflow complexity score to determine thinking mode for all agents in this workflow.

**EXECUTE NOW**:

1. ANALYZE workflow description for complexity indicators
2. CALCULATE complexity score using this algorithm:

   ```
   score = 0
   score += count_keywords(["implement", "architecture", "redesign"]) × 3
   score += count_keywords(["add", "improve", "refactor"]) × 2
   score += count_keywords(["security", "breaking", "core"]) × 4
   score += estimated_file_count / 5
   score += (research_topics_needed - 1) × 2
   ```

3. MAP complexity score to thinking mode:
   - score 0-3: No special thinking mode (standard processing)
   - score 4-6: "think" (moderate complexity, careful reasoning)
   - score 7-9: "think hard" (high complexity, deep analysis)
   - score 10+: "think harder" (critical decisions, security implications)

4. STORE thinking_mode in workflow_state for use in all agent prompts

**Examples**:

"Add hello world function"
→ Keywords: "add" (×1) = 2 points, files: ~1 = 0 points, topics: 0 = 0 points
→ Total: 2 (Simple, no thinking mode)

"Implement user authentication system"
→ Keywords: "implement" (×1) = 3 points, "authentication" suggests security context
→ Files: ~8-10 = 2 points, topics: 3 = 4 points
→ Total: 9 (Complex, thinking mode: "think hard")

"Refactor core security module with breaking changes"
→ Keywords: "refactor" (×1) = 2, "security" (×1) = 4, "breaking" (×1) = 4, "core" (×1) = 4
→ Files: ~15 = 3 points, topics: 4 = 6 points
→ Total: 23 (Critical, thinking mode: "think harder")

This thinking mode will be prepended to ALL agent prompts in subsequent phases.

**State Management**:

UPDATE workflow_state after determining thinking mode and research strategy:

```yaml
workflow_state.thinking_mode = "[calculated thinking mode]"
workflow_state.current_phase = "research"
workflow_state.execution_tracking.phase_start_times["analysis"] = [current timestamp]
workflow_state.execution_tracking.phase_end_times["analysis"] = [current timestamp]
workflow_state.completed_phases.append("analysis")
```

UPDATE TodoWrite to mark analysis complete and research as in-progress:

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
      "status": "in_progress",
      "activeForm": "Executing parallel research phase"
    },
    // ... remaining todos unchanged ...
  ]
}
```

#### Step 2: Determine Absolute Report Paths

**CRITICAL**: Before invoking research agents, calculate ABSOLUTE paths for all report files.

**EXECUTE NOW**: For EACH research topic identified in Step 1:

1. **Detect Specs Directory Location**:
   ```bash
   # Priority order for specs directory location:
   # 1. Check .claude/SPECS.md for registered specs directories
   # 2. If no SPECS.md, check for .claude/specs/ directory
   # 3. Fall back to project root specs/ directory

   PROJECT_ROOT="/home/benjamin/.config"  # Current working directory
   CLAUDE_DIR="${PROJECT_ROOT}/.claude"

   # For Claude Code features, prefer .claude/specs/
   if [ -d "${CLAUDE_DIR}/specs" ]; then
     SPECS_DIR="${CLAUDE_DIR}/specs"
   elif [ -f "${CLAUDE_DIR}/SPECS.md" ]; then
     # Parse SPECS.md for registered directory
     SPECS_DIR=$(grep "^- Path:" "${CLAUDE_DIR}/SPECS.md" | head -1 | cut -d: -f2 | tr -d ' ')
   else
     # Default to project root
     SPECS_DIR="${PROJECT_ROOT}/specs"
   fi
   ```

2. **Construct Topic Directory Path**:
   ```bash
   TOPIC_SLUG="orchestrate_improvements"  # From Step 3.5
   REPORT_DIR="${SPECS_DIR}/reports/${TOPIC_SLUG}"

   # Ensure directory exists before invoking agents
   mkdir -p "${REPORT_DIR}"
   ```

3. **Calculate Next Report Number**:
   ```bash
   # Find highest existing report number in topic directory
   NEXT_NUM=$(find "${REPORT_DIR}" -name "[0-9][0-9][0-9]_*.md" 2>/dev/null | wc -l)
   NEXT_NUM=$((NEXT_NUM + 1))
   REPORT_NUM=$(printf "%03d" ${NEXT_NUM})
   ```

4. **Construct ABSOLUTE Report Path**:
   ```bash
   REPORT_NAME="001_existing_patterns_analysis.md"  # Descriptive name
   REPORT_PATH="${REPORT_DIR}/${REPORT_NAME}"

   # CRITICAL: This must be an ABSOLUTE path
   # Example: /home/benjamin/.config/.claude/specs/reports/orchestrate_improvements/001_existing_patterns_analysis.md
   # NOT: specs/reports/orchestrate_improvements/001_existing_patterns_analysis.md
   ```

5. **Store in Workflow State**:
   ```yaml
   workflow_state.research_reports[agent_index] = {
     "agent_index": 1,
     "topic": "existing_patterns",
     "topic_slug": "existing_patterns",
     "expected_path": "${REPORT_PATH}",  # ABSOLUTE path
     "created_at": null,  # Will be set after agent completes
     "verified": false,   # Will be set in Step 4.5
     "retry_count": 0
   }
   ```

**Why Absolute Paths Are Critical**:

When research agents receive RELATIVE paths (e.g., `specs/reports/topic/001_report.md`), they interpret them from different base directories, resulting in reports scattered across multiple locations. This was discovered empirically when /orchestrate research agents created reports in inconsistent locations (2 at project root, 1 in .claude/).

By providing ABSOLUTE paths (e.g., `/home/benjamin/.config/.claude/specs/reports/topic/001_report.md`), all agents create reports at exactly the same location, ensuring consistent report collection.

#### Step 2.5: Launch Parallel Research Agents

**EXECUTE NOW**: USE the Task tool to invoke research-specialist agents in parallel.

For EACH research topic identified in Step 1:

INVOKE a research-specialist agent using the Task tool with these exact parameters:

```json
{
  "subagent_type": "general-purpose",
  "description": "Research [TOPIC_NAME] using research-specialist protocol",
  "prompt": "Read and follow the behavioral guidelines from:\n/home/benjamin/.config/.claude/agents/research-specialist.md\n\nYou are acting as a Research Specialist Agent with the tools and constraints defined in that file.\n\n[COMPLETE PROMPT FROM STEP 3 - SEE BELOW]"
}
```

**CRITICAL**: Send ALL research Task invocations in a SINGLE MESSAGE.

This enables parallel execution. Do NOT send Task invocations sequentially - they must all be in one response to execute concurrently.

**Example Parallel Invocation** (3 research topics):

```
Here are three research tasks to execute in parallel:

[Task tool invocation #1 for existing_patterns]
[Task tool invocation #2 for security_practices]
[Task tool invocation #3 for framework_implementations]
```

**WAIT** for all research agents to complete before proceeding to Step 3.5.

**Monitoring**:
- Watch for PROGRESS: markers from each agent
- Collect REPORT_PATH: outputs as agents complete
- Verify all agents complete successfully before moving to Step 4

#### Step 3: Complete Research Agent Prompt Template

The following template is used for EACH research-specialist agent invocation in Step 2.5.

**SUBSTITUTE** these placeholders before invoking:
- [THINKING_MODE]: Value from Step 1.5 (think, think hard, think harder, or empty)
- [TOPIC_TITLE]: Research topic title (e.g., "Authentication Patterns in Codebase")
- [USER_WORKFLOW]: Original user workflow description (1 line)
- [PROJECT_NAME]: Generated in Step 3.5
- [TOPIC_SLUG]: Generated in Step 3.5
- [SPECS_DIR]: Path to specs directory (from SPECS.md or auto-detected)
- [ABSOLUTE_REPORT_PATH]: ABSOLUTE path calculated in Step 2 (CRITICAL - must be absolute)
- [COMPLEXITY_LEVEL]: Simple|Medium|Complex|Critical (from Step 1.5)
- [SPECIFIC_REQUIREMENTS]: What this agent should investigate

**Complete Prompt Template**:

```markdown
**Thinking Mode**: [THINKING_MODE]

# Research Task: [TOPIC_TITLE]

## Context
- **Workflow**: [USER_WORKFLOW]
- **Project Name**: [PROJECT_NAME]
- **Topic Slug**: [TOPIC_SLUG]
- **Research Focus**: [SPECIFIC_REQUIREMENTS]
- **Project Standards**: /home/benjamin/.config/CLAUDE.md
- **Complexity Level**: [COMPLEXITY_LEVEL]

## Objective
Investigate [SPECIFIC_REQUIREMENTS] to inform planning and implementation phases.

## Specs Directory Context
- **Specs Directory Detection**:
  1. Check .claude/SPECS.md for registered specs directories
  2. If no SPECS.md, use Glob to find existing specs/ directories
  3. Default to project root specs/ if none found
- **Report Location**: Create report in [SPECS_DIR]/reports/[TOPIC_SLUG]/NNN_report_name.md
- **Include in Metadata**: Add "Specs Directory" field to report metadata

## Research Requirements

[SPECIFIC_REQUIREMENTS - Agent should investigate these areas:]

### For "existing_patterns" Topics:
- Search codebase for related implementations using Grep/Glob
- Read relevant source files to understand current patterns
- Identify architectural decisions and design patterns used
- Document file locations with line number references
- Note any inconsistencies or technical debt

### For "best_practices" Topics:
- Use WebSearch to find 2025-current best practices
- Focus on authoritative sources (official docs, security guides)
- Compare industry standards with current implementation
- Identify gaps between best practices and current state
- Recommend specific improvements

### For "alternatives" Topics:
- Research 2-3 alternative implementation approaches
- Document pros/cons of each alternative
- Consider trade-offs (performance, complexity, maintainability)
- Recommend which alternative best fits this project
- Provide concrete examples from similar projects

### For "constraints" Topics:
- Identify technical limitations (platform, dependencies, performance)
- Document security considerations and requirements
- Note compatibility requirements (backwards compatibility, API contracts)
- Consider resource constraints (time, team expertise, infrastructure)
- Flag high-risk areas requiring careful design

## Report File Creation

You MUST create a research report file using the Write tool. Do NOT return only a summary.

**CRITICAL: Use the Provided Absolute Path**:

The orchestrator has calculated an ABSOLUTE report file path for you. You MUST use this exact path when creating the report file:

**Report Path**: [ABSOLUTE_REPORT_PATH]

Example: `/home/benjamin/.config/.claude/specs/reports/orchestrate_improvements/001_existing_patterns.md`

**DO NOT**:
- Recalculate the path yourself
- Use relative paths (e.g., `specs/reports/...`)
- Change the directory location
- Modify the report number

**DO**:
- Use the Write tool with the exact path provided above
- Create the report at the specified ABSOLUTE path
- Return this exact path in your REPORT_PATH: output

**Report Structure** (use this exact template):

```markdown
# [Report Title]

## Metadata
- **Date**: YYYY-MM-DD
- **Specs Directory**: [SPECS_DIR]
- **Report Number**: NNN (within topic subdirectory)
- **Topic**: [TOPIC_SLUG]
- **Created By**: /orchestrate (research phase)
- **Workflow**: [USER_WORKFLOW]

## Implementation Status
- **Status**: Research Complete
- **Plan**: (will be added by plan-architect)
- **Implementation**: (will be added after implementation)
- **Date**: YYYY-MM-DD

## Research Focus
[Description of what this research investigated]

## Findings

### Current State Analysis
[Detailed findings from codebase analysis - include file references with line numbers]

### Industry Best Practices
[Findings from web research - include authoritative sources]

### Key Insights
[Important discoveries, patterns identified, issues found]

## Recommendations

### Primary Recommendation: [Approach Name]
**Description**: [What this approach entails]
**Pros**:
- [Advantage 1]
- [Advantage 2]
**Cons**:
- [Limitation 1]
**Suitability**: [Why this fits the project]

### Alternative Approach: [Approach Name]
[Secondary recommendation if applicable]

## Potential Challenges
- [Challenge 1 and mitigation strategy]
- [Challenge 2 and mitigation strategy]

## References
- [File: path/to/file.ext, lines X-Y - description]
- [URL: https://... - authoritative source]
- [Related code: path/to/related.ext]
```

## Expected Output

**Primary Output**: Report file path in this exact format:
```
REPORT_PATH: [ABSOLUTE_REPORT_PATH]
```

**CRITICAL**: This must be the exact ABSOLUTE path provided to you by the orchestrator. Do NOT output a relative path.

**Secondary Output**: Brief summary (1-2 sentences):
- What was researched
- Key finding or primary recommendation

**Example Output**:
```
REPORT_PATH: /home/benjamin/.config/.claude/specs/reports/existing_patterns/001_auth_patterns.md

Research investigated current authentication implementations in the codebase. Found
session-based auth using Redis with 30-minute TTL. Primary recommendation: Extend
existing session pattern rather than implementing OAuth from scratch.
```

## Success Criteria
- Report file created at correct path with correct number
- Report includes all required metadata fields
- Findings include specific file references with line numbers
- Recommendations are actionable and project-specific
- Report path returned in parseable format (REPORT_PATH: ...)
```

End of prompt template.

#### Step 3.5: Generate Project Name and Topic Slugs

**EXECUTE NOW**: Generate project name and topic slugs BEFORE invoking research agents (Step 2).

**Project Name Generation Algorithm**:

1. EXTRACT key terms from workflow description
2. REMOVE common words: [the, a, an, implement, add, create, build, develop, refactor, update, fix]
3. JOIN remaining words with underscores
4. CONVERT to lowercase
5. LIMIT to 3-4 words maximum
6. STORE in workflow_state.project_name

**Examples**:

"Implement user authentication system"
→ Extract: [Implement, user, authentication, system]
→ Remove: [Implement] (common word)
→ Remaining: [user, authentication, system]
→ Result: "user_authentication_system" (3 words)

"Add payment processing flow"
→ Extract: [Add, payment, processing, flow]
→ Remove: [Add] (common word)
→ Remaining: [payment, processing, flow]
→ Result: "payment_processing_flow" (3 words)

"Refactor session management"
→ Extract: [Refactor, session, management]
→ Remove: [Refactor] (common word)
→ Remaining: [session, management]
→ Result: "session_management" (2 words)

**Topic Slug Generation Algorithm** (for EACH research topic):

1. EXTRACT key terms from research topic description
2. REMOVE common words: [the, a, an, in, for, with, how, what, patterns, approaches]
3. JOIN remaining words with underscores
4. CONVERT to lowercase
5. KEEP concise (2-3 words maximum)
6. STORE in workflow_state.topic_slugs array (same order as research_topics)

**Examples**:

"Existing auth patterns in codebase"
→ Extract: [Existing, auth, patterns, in, codebase]
→ Remove: [in] (common word)
→ Keep: [existing, patterns] (concise)
→ Result: "existing_patterns"

"Security best practices for authentication (2025)"
→ Extract: [Security, best, practices, for, authentication]
→ Remove: [for] (common word)
→ Keep: [security, practices]
→ Result: "security_practices"

"Framework-specific authentication implementations"
→ Extract: [Framework, specific, authentication, implementations]
→ Keep: [framework, implementations] (concise)
→ Result: "framework_implementations"

**Common Topic Slugs** (use as guidance for consistency):
- existing_patterns
- best_practices
- security_practices
- alternatives
- framework_implementations
- performance_considerations
- migration_strategy
- integration_approaches

**VERIFY** before proceeding:
- workflow_state.project_name is set (will be used in specs path)
- workflow_state.topic_slugs array matches number of research_topics
- All slugs are lowercase with underscores only (no spaces, hyphens)

These values are used in Step 2 when constructing research agent prompts and report file paths.

#### Step 3a: Monitor Research Agent Execution

After invoking all research agents in Step 2.5, MONITOR their progress and execution with detailed visibility.

**EXECUTE NOW**:

1. **Emit Research Phase Start Marker**:
   ```
   PROGRESS: Starting Research Phase (N agents, parallel execution)
   ```
   Where N is the number of research agents invoked.

2. **Watch for Per-Agent Progress Markers**:

   Each research agent should emit standardized progress markers in this format:
   ```
   PROGRESS: [Agent N/M: topic_slug] Status message
   ```

   Expected progression for each agent:
   - `PROGRESS: [Agent 1/3: existing_patterns] Starting research...`
   - `PROGRESS: [Agent 1/3: existing_patterns] Analyzing codebase...`
   - `PROGRESS: [Agent 1/3: existing_patterns] Searching best practices...`
   - `PROGRESS: [Agent 1/3: existing_patterns] Writing report file...`
   - `PROGRESS: [Agent 1/3: existing_patterns] Report created ✓`

3. **Watch for Report Creation Markers**:

   When a report file is successfully created, the agent emits:
   ```
   REPORT_CREATED: /absolute/path/to/report.md
   ```

   Example:
   ```
   REPORT_CREATED: /home/benjamin/.config/.claude/specs/reports/existing_patterns/001_auth_patterns.md
   ```

   **IMPORTANT**: Report path must be ABSOLUTE (verify it starts with `/`).

4. **Display Aggregated Progress to User**:

   As progress markers arrive, display consolidated view:
   ```
   PROGRESS: Starting Research Phase (3 agents, parallel execution)
   PROGRESS: [Agent 1/3: existing_patterns] Analyzing codebase...
   PROGRESS: [Agent 2/3: security_practices] Searching best practices...
   PROGRESS: [Agent 3/3: alternatives] Comparing approaches...
   PROGRESS: [Agent 1/3: existing_patterns] Report created ✓
   REPORT_CREATED: /home/benjamin/.config/.claude/specs/reports/existing_patterns/001_analysis.md
   PROGRESS: [Agent 2/3: security_practices] Report created ✓
   REPORT_CREATED: /home/benjamin/.config/.claude/specs/reports/security_practices/001_practices.md
   PROGRESS: [Agent 3/3: alternatives] Report created ✓
   REPORT_CREATED: /home/benjamin/.config/.claude/specs/reports/alternatives/001_comparison.md
   ```

5. **Track Completion Status**:

   Maintain completion tracking:
   ```yaml
   agent_status:
     agent_1: completed  # Report created successfully
     agent_2: completed  # Report created successfully
     agent_3: in_progress  # Still working
   ```

6. **Wait for ALL Agents to Complete**:

   Before proceeding to Step 4, ensure all agents have reached one of these states:
   - **completed**: Report created successfully (REPORT_CREATED marker received)
   - **failed**: Agent returned error or timeout
   - **partial**: Agent completed but report file missing (will be handled in Step 4.5)

7. **Check for Agent Errors or Failures**:

   - **Single agent fails**: Note error, collect available reports, continue
   - **Multiple agents fail**: Assess whether remaining reports sufficient for planning
   - **All agents fail**: Escalate to user with detailed error summary
   - **Partial success**: Proceed with available reports, flag missing reports for retry

8. **Emit Research Phase Completion Summary**:

   After all agents complete:
   ```
   PROGRESS: Research Phase complete - N/M reports created (R retries needed)
   ```

   Example:
   ```
   PROGRESS: Research Phase complete - 3/3 reports verified (0 retries needed)
   ```

**Progress Marker Format Standards**:

- **Phase Markers**: `PROGRESS: [Phase description]`
- **Agent Markers**: `PROGRESS: [Agent N/M: topic] Status`
- **Report Markers**: `REPORT_CREATED: /absolute/path/to/report.md`
- **Completion Markers**: `PROGRESS: Phase complete - N/M reports verified (R retries)`

**Expected Agent Completion Time**:
- Simple research: 1-2 minutes per agent
- Medium research: 2-4 minutes per agent
- Complex research: 4-6 minutes per agent

**Parallel Execution Benefit**:
- Sequential (one after another): 3 agents × 3 minutes = 9 minutes
- Parallel (all at once): max(3 minutes) = 3 minutes
- Time saved: ~66% for 3 agents

**Error Progress Markers**:

If an agent encounters errors:
```
PROGRESS: [Agent 2/3: security_practices] ERROR - Failed to create report
ERROR: Agent 2 (security_practices): Write tool failed - permission denied
```

**TodoWrite Integration**:

Update task list to show per-agent progress:
```json
{
  "todos": [
    {
      "content": "Research Agent 1/3: existing_patterns",
      "status": "completed",
      "activeForm": "Researching existing_patterns"
    },
    {
      "content": "Research Agent 2/3: security_practices",
      "status": "in_progress",
      "activeForm": "Researching security_practices"
    },
    {
      "content": "Research Agent 3/3: alternatives",
      "status": "pending",
      "activeForm": "Researching alternatives"
    }
  ]
}
```

Proceed to Step 4 only after all agents complete or fail definitively.

#### Step 4: Collect Report Paths from Agent Output

EXTRACT report file paths from completed research agent outputs.

**EXECUTE NOW**:

For EACH completed research agent:

1. PARSE agent output for report path line:
   - Expected format: "REPORT_PATH: [path]"
   - Example: "REPORT_PATH: specs/reports/existing_patterns/001_auth_patterns.md"

2. EXTRACT the file path:
   - Remove "REPORT_PATH: " prefix
   - Trim whitespace
   - Validate path format (must contain specs/reports/{topic}/)

3. VALIDATE report file exists:
   ```bash
   # Use Read tool or Bash to verify
   if [ -f "$REPORT_PATH" ]; then
     echo "✓ Report exists: $REPORT_PATH"
   else
     echo "✗ Report missing: $REPORT_PATH"
     # Flag for retry or manual intervention
   fi
   ```

4. STORE valid report path in workflow_state.research_reports array:
   ```yaml
   workflow_state.research_reports: [
     "specs/reports/existing_patterns/001_auth_patterns.md",
     "specs/reports/security_practices/001_best_practices.md",
     "specs/reports/framework_implementations/001_lua_auth.md"
   ]
   ```

**Path Extraction Examples**:

Agent Output:
```
I've completed research on authentication patterns in the codebase.

REPORT_PATH: specs/reports/existing_patterns/001_auth_patterns.md

Summary: Found session-based auth using Redis with 30-minute TTL...
```

Extracted: `specs/reports/existing_patterns/001_auth_patterns.md`

**Context Reduction Achieved**:
- **Before**: Pass 200+ words of research summary to planning phase
- **After**: Pass 1 file path (~50 characters) to planning phase
- **Reduction**: 97% context savings per report
- **With 3 reports**: 600 words → 150 characters (99.75% savings)

**VERIFICATION CHECKLIST**:
- [ ] All research agents completed (or failed definitively)
- [ ] Report path extracted from each successful agent
- [ ] Report files exist and are readable
- [ ] Report paths stored in workflow_state.research_reports array
- [ ] Number of reports matches number of successful agents

Proceed to Step 4.5 for comprehensive verification.

#### Step 4.5: Verify Report Files (Batch Verification)

**CRITICAL**: Perform comprehensive verification of all reports including path consistency checks.

This step addresses the path inconsistency issue discovered in Report 004 where agents created
reports at different locations than expected.

**EXECUTE NOW**:

For EACH report in workflow_state.research_reports:

1. **Extract Expected Path**:
   ```yaml
   expected_path = workflow_state.research_reports[agent_index].expected_path
   # This is the ABSOLUTE path provided to agent in Step 2
   # Example: /home/benjamin/.config/.claude/specs/reports/orchestrate_improvements/001_report.md
   ```

2. **Verify File Exists at Expected Path** (CRITICAL):
   ```bash
   # Check if file exists at exact path specified
   if [ -f "$expected_path" ]; then
     echo "✓ Report exists at expected path: $expected_path"
     verified=true
   else
     echo "✗ MISSING at expected path: $expected_path"
     verified=false
   fi
   ```

3. **Search for Report in Other Locations** (Path Mismatch Detection):

   If file not found at expected path, search for it elsewhere:
   ```bash
   # Extract report filename from expected path
   REPORT_FILENAME=$(basename "$expected_path")
   TOPIC_SLUG=$(echo "$expected_path" | grep -oP "reports/\K[^/]+")

   # Search in common alternative locations
   find /home/benjamin/.config -name "$REPORT_FILENAME" \
     -path "*/specs/reports/${TOPIC_SLUG}/*" 2>/dev/null

   # Common alternative locations to check:
   # - Project root: /home/benjamin/.config/specs/reports/topic/
   # - Claude dir: /home/benjamin/.config/.claude/specs/reports/topic/
   # - Working dir: ./specs/reports/topic/
   ```

4. **Classify Verification Result**:

   ```yaml
   verification_status:
     success: File exists at expected absolute path
     path_mismatch: File exists but at different location
     file_not_found: No file found anywhere
     invalid_metadata: File exists but metadata incomplete
     permission_denied: File exists but cannot read
   ```

5. **Validate Report Metadata** (if file found):

   ```bash
   # Check first 30 lines for required metadata
   head -30 "$REPORT_PATH" | grep -E "^## Metadata" >/dev/null
   if [ $? -eq 0 ]; then
     # Check for required fields
     head -30 "$REPORT_PATH" | grep -E "^- \*\*Date\*\*:" >/dev/null && \
     head -30 "$REPORT_PATH" | grep -E "^- \*\*Topic\*\*:" >/dev/null && \
     head -30 "$REPORT_PATH" | grep -E "^- \*\*Research Focus\*\*:" >/dev/null

     if [ $? -eq 0 ]; then
       echo "✓ Metadata complete"
       metadata_valid=true
     else
       echo "✗ Metadata incomplete"
       metadata_valid=false
     fi
   else
     echo "✗ No metadata section found"
     metadata_valid=false
   fi
   ```

6. **Build Agent-to-Report Mapping**:

   Store comprehensive mapping in workflow_state for debugging:
   ```yaml
   workflow_state.research_reports[agent_index] = {
     "agent_index": 1,
     "topic": "existing_patterns",
     "topic_slug": "existing_patterns",
     "expected_path": "/home/benjamin/.config/.claude/specs/reports/existing_patterns/001_analysis.md",
     "actual_path": "/home/benjamin/.config/.claude/specs/reports/existing_patterns/001_analysis.md",  # Same if verified
     "created_at": "2025-10-13T14:30:22Z",
     "verified": true,
     "verification_status": "success",
     "metadata_valid": true,
     "retry_count": 0
   }
   ```

7. **Aggregate Verification Results**:

   ```yaml
   verification_summary:
     total_reports: 3
     verified_success: 2    # Reports at expected paths
     path_mismatch: 1       # Reports found at different locations
     file_not_found: 0      # Reports completely missing
     invalid_metadata: 0    # Reports with incomplete metadata
     permission_denied: 0   # Reports that cannot be read
   ```

**Verification Decision Tree**:

```
For EACH report:
  ├─ File at expected path?
  │  ├─ YES
  │  │  ├─ Metadata valid?
  │  │  │  ├─ YES → Status: success, verified: true
  │  │  │  └─ NO → Status: invalid_metadata, verified: false
  │  │  └─ Cannot read?
  │  │     └─ YES → Status: permission_denied, verified: false
  │  │
  │  └─ NO (not at expected path)
  │     ├─ Search finds file elsewhere?
  │     │  ├─ YES → Status: path_mismatch, verified: false
  │     │  │        actual_path: [found location]
  │     │  └─ NO → Status: file_not_found, verified: false
  │     │
  │     └─ Check REPORT_CREATED marker in agent output
  │        ├─ Marker found → Parse actual path from marker
  │        └─ No marker → file_not_found
```

**Display Verification Summary**:

After verifying all reports, display summary:
```
PROGRESS: Verifying research reports...

✓ Report 1/3: existing_patterns - verified at expected path
✗ Report 2/3: security_practices - PATH MISMATCH
  Expected: /home/benjamin/.config/.claude/specs/reports/security_practices/001_practices.md
  Actual:   /home/benjamin/.config/specs/reports/security_practices/001_practices.md
✓ Report 3/3: alternatives - verified at expected path

Verification Summary:
- Total Reports: 3
- Verified Successfully: 2
- Path Mismatches: 1
- Missing Reports: 0

NEXT: Proceeding to Step 4.6 (Retry Failed Reports) for 1 failed verification
```

**Proceed Based on Results**:

- **All reports verified** (verified: true for all):
  → Skip Step 4.6, proceed directly to Step 5 (Save Checkpoint)
  → Display: "PROGRESS: All reports verified - proceeding to planning phase"

- **Some reports failed verification**:
  → Proceed to Step 4.6 (Retry Failed Reports)
  → Pass failed report list to retry logic

- **All reports failed verification**:
  → Escalate to user with detailed error report
  → Display: "ERROR: All research reports failed verification - see details above"

**Update Workflow State**:

```yaml
workflow_state.research_phase_data.verification_summary = {
  "total_reports": 3,
  "verified_success": 2,
  "path_mismatch": 1,
  "file_not_found": 0,
  "invalid_metadata": 0,
  "permission_denied": 0,
  "verification_timestamp": "2025-10-13T14:35:00Z"
}

workflow_state.research_phase_data.failed_reports = [
  {
    "agent_index": 2,
    "topic": "security_practices",
    "expected_path": "/home/benjamin/.config/.claude/specs/reports/security_practices/001_practices.md",
    "actual_path": "/home/benjamin/.config/specs/reports/security_practices/001_practices.md",
    "status": "path_mismatch"
  }
]
```

**Error Classifications** (using error-utils.sh):

```bash
# Source error utilities
source .claude/lib/error-utils.sh

# Classify each verification failure
case "$verification_status" in
  file_not_found)
    error_type=$(classify_error "report_missing" "Report file not found after agent completion")
    ;;
  path_mismatch)
    error_type=$(classify_error "path_inconsistency" "Report created at different location than expected")
    ;;
  invalid_metadata)
    error_type=$(classify_error "incomplete_output" "Report metadata section incomplete")
    ;;
  permission_denied)
    error_type=$(classify_error "file_access" "Cannot read report file - permission denied")
    ;;
esac
```

**Benefits of Batch Verification**:

- **Preserves Parallelism**: Verification happens AFTER all agents complete (not during)
- **Complete Picture**: See all verification results before deciding on retry strategy
- **Path Mismatch Detection**: Discover path interpretation issues (Report 004 finding)
- **Detailed Diagnostics**: Build comprehensive agent-to-report mapping for debugging
- **Efficient Retry**: Only retry actually failed agents, not all agents

Proceed to Step 4.6 if any reports failed verification, otherwise skip to Step 5.

#### Step 4.6: Retry Failed Reports (Error Recovery)

**CRITICAL**: Handle verification failures with intelligent retry logic and path correction.

This step provides automatic recovery from path inconsistencies and transient failures discovered
during verification (Step 4.5).

**EXECUTE NOW** (only if Step 4.5 reported failures):

For EACH failed report from workflow_state.research_phase_data.failed_reports:

**Step 1: Identify Failed Agent**

```yaml
failed_report = workflow_state.research_phase_data.failed_reports[i]
agent_index = failed_report.agent_index
topic = failed_report.topic
topic_slug = failed_report.topic_slug
verification_status = failed_report.status
expected_path = failed_report.expected_path
actual_path = failed_report.actual_path  # May be null if file_not_found
```

**Step 2: Classify Error Type and Determine Retry Strategy**

Use error-utils.sh to classify error and determine if retryable:

```bash
source .claude/lib/error-utils.sh

case "$verification_status" in
  file_not_found)
    # Report completely missing after agent completion
    error_classification="transient"  # Likely timing issue or agent error
    retry_strategy="reinvoke_agent"
    retryable=true
    ;;

  path_mismatch)
    # Report exists but at wrong location (CRITICAL - Report 004 issue)
    error_classification="path_interpretation"
    retry_strategy="move_file_or_retry"  # Two options
    retryable=true
    ;;

  invalid_metadata)
    # Report exists but metadata incomplete
    error_classification="incomplete_output"
    retry_strategy="fix_metadata_or_retry"
    retryable=true
    ;;

  permission_denied)
    # Cannot read report file (system issue)
    error_classification="infrastructure"
    retry_strategy="escalate"  # Not retryable by agent
    retryable=false
    ;;

  agent_crashed)
    # Agent returned error during execution
    error_classification="agent_failure"
    retry_strategy="reinvoke_agent"
    retryable=true
    ;;
esac
```

**Step 3: Handle Path Mismatch** (CRITICAL - Report 004 Recovery)

If verification_status == "path_mismatch":

```bash
# Option 1: Move file to correct location (PREFERRED - faster, preserves work)
if [ -f "$actual_path" ]; then
  echo "PROGRESS: [Agent $agent_index/$total_agents: $topic] Correcting path mismatch..."

  # Ensure target directory exists
  expected_dir=$(dirname "$expected_path")
  mkdir -p "$expected_dir"

  # Move file from actual location to expected location
  mv "$actual_path" "$expected_path"

  if [ $? -eq 0 ]; then
    echo "✓ File moved successfully to: $expected_path"

    # Update workflow_state
    workflow_state.research_reports[agent_index].actual_path = "$expected_path"
    workflow_state.research_reports[agent_index].verified = true
    workflow_state.research_reports[agent_index].verification_status = "success"
    workflow_state.research_reports[agent_index].recovery_method = "file_moved"

    # Remove from failed_reports list
    # Continue to next failed report
    continue
  else
    echo "✗ File move failed - falling back to agent retry"
    retry_strategy="reinvoke_agent"
  fi
fi

# Option 2: Retry agent with EMPHASIZED absolute path (fallback)
# Only if file move failed or file not found
echo "PROGRESS: [Agent $agent_index/$total_agents: $topic] Retrying with emphasized path..."
retry_strategy="reinvoke_agent_emphasize_path"
```

**Step 4: Handle Metadata Fixes**

If verification_status == "invalid_metadata" and file exists:

```bash
# Attempt quick metadata fix without full retry
echo "PROGRESS: [Agent $agent_index/$total_agents: $topic] Attempting metadata fix..."

# Read current report
current_content=$(cat "$expected_path")

# Check what metadata is missing
missing_date=$(echo "$current_content" | grep -q "^- \*\*Date\*\*:" || echo "true")
missing_topic=$(echo "$current_content" | grep -q "^- \*\*Topic\*\*:" || echo "true")

if [ "$missing_date" = "true" ] || [ "$missing_topic" = "true" ]; then
  # Try to prepend metadata section
  metadata_fix_possible=true
  # Use Edit tool to add metadata
  # If successful, mark verified and continue
  # If fails, fall back to agent retry
fi
```

**Step 5: Retrieve Agent Prompt for Retry**

If retry_strategy requires agent reinvocation:

```yaml
# Agent prompts stored in Step 2 before invocation
agent_prompt = workflow_state.research_phase_data.agent_prompts[topic_slug]

# Verify prompt exists
if agent_prompt is null:
  echo "ERROR: Cannot retry - agent prompt not stored in checkpoint"
  mark_as_escalated
  continue
```

**Step 6: Check Retry Count Limit**

Before retrying, enforce retry limit (prevents infinite loops):

```yaml
current_retry_count = workflow_state.research_reports[agent_index].retry_count

if current_retry_count >= 1:
  echo "ERROR: Max retry limit reached for agent $agent_index ($topic)"
  echo "Agent has already been retried $current_retry_count times"
  mark_as_escalated
  add_to_final_failed_reports
  continue
```

**Step 7: Reinvoke Agent with Modified Prompt** (if retryable)

```bash
# For path_mismatch retry, emphasize absolute path requirement
if [ "$retry_strategy" = "reinvoke_agent_emphasize_path" ]; then
  path_emphasis="

**CRITICAL PATH REQUIREMENT**:
Your previous invocation created the report at a different location than expected.
You MUST use this EXACT ABSOLUTE PATH when creating the report:

  $expected_path

DO NOT use relative paths. DO NOT modify this path. Use it exactly as provided.
"
  agent_prompt="${path_emphasis}\n\n${agent_prompt}"
fi

# For file_not_found retry, emphasize file creation requirement
if [ "$verification_status" = "file_not_found" ]; then
  file_emphasis="

**CRITICAL FILE CREATION REQUIREMENT**:
Your previous invocation did not create a report file.
You MUST use the Write tool to create a file at:

  $expected_path

Do NOT return only a summary. The file MUST be created.
"
  agent_prompt="${file_emphasis}\n\n${agent_prompt}"
fi

# Emit progress marker
echo "PROGRESS: [Agent $agent_index/$total_agents: $topic] Retrying (attempt 1/1)..."

# Invoke agent using Task tool
# (Same invocation pattern as Step 2.5)
```

**Step 8: Verify Retry Result**

After retry agent completes:

```bash
# Re-run verification for this specific report
# (Same logic as Step 4.5)

if [ verification successful ]; then
  echo "✓ Retry successful for agent $agent_index ($topic)"

  # Update workflow_state
  workflow_state.research_reports[agent_index].verified = true
  workflow_state.research_reports[agent_index].retry_count += 1
  workflow_state.research_reports[agent_index].recovery_method = "agent_retry"

  # Remove from failed list
  continue
else
  echo "✗ Retry failed for agent $agent_index ($topic)"

  # Update workflow_state
  workflow_state.research_reports[agent_index].retry_count += 1
  workflow_state.research_reports[agent_index].recovery_method = "retry_failed"

  # Add to final failed reports for escalation
  add_to_final_failed_reports
fi
```

**Error Output Examples**:

```
# file_not_found
PROGRESS: [Agent 2/3: security_practices] Retrying (attempt 1/1)...
ERROR: Report missing for Agent 2/3 (topic: security_practices)
Expected: /home/benjamin/.config/.claude/specs/reports/security_practices/001_practices.md
Agent completed successfully but report file not found at expected location.
Retrying agent invocation with emphasized file creation requirement...

# path_mismatch (CRITICAL - Report 004)
PROGRESS: [Agent 1/3: existing_patterns] Correcting path mismatch...
✓ File moved successfully to: /home/benjamin/.config/.claude/specs/reports/existing_patterns/001_analysis.md

# invalid_metadata
PROGRESS: [Agent 3/3: alternatives] Attempting metadata fix...
✓ Metadata fields added successfully

# agent_crashed
PROGRESS: [Agent 2/3: security_practices] Retrying (attempt 1/1)...
ERROR: Agent failed for topic: security_practices
Agent output indicates crash or error condition.
Retrying agent invocation with same prompt...

# permission_denied (not retryable)
ERROR: Cannot read report for Agent 2/3 (topic: security_practices)
Path: /home/benjamin/.config/.claude/specs/reports/security_practices/001_practices.md
Permission denied - this is a system issue, not retryable by agent.
Escalating to user.
```

**Step 9: Aggregate Retry Results**

After all retries complete:

```yaml
retry_summary:
  total_retries_attempted: 2
  successful_recoveries: 1
  failed_recoveries: 1
  recovery_methods:
    file_moved: 1       # Path mismatch corrected by moving file
    agent_retry: 0      # Agent reinvoked and succeeded
    metadata_fixed: 0   # Metadata corrected without retry
    retry_failed: 1     # Retry attempted but still failed
    escalated: 0        # Not retryable, escalated to user
```

**Display Retry Summary**:

```
PROGRESS: Retry phase complete

Retry Summary:
- Retries Attempted: 2
- Successful Recoveries: 1
  - Path mismatch corrected: 1
  - Agent retry succeeded: 0
- Failed Recoveries: 1
  - Will proceed with 2/3 reports

Updated Report Status:
✓ Report 1/3: existing_patterns - recovered (file moved)
✗ Report 2/3: security_practices - FAILED (retry exhausted)
✓ Report 3/3: alternatives - verified

NEXT: Proceeding to Step 5 (Save Checkpoint) with 2 verified reports
```

**Step 10: Determine Next Action**

```yaml
total_reports = workflow_state.research_reports.length
verified_reports = count(verified: true)
failed_reports = count(verified: false)

if failed_reports == 0:
  # All reports verified (including recoveries)
  display("PROGRESS: All reports verified after recovery - proceeding to planning")
  proceed_to_step_5()

elif verified_reports >= (total_reports / 2):
  # Majority verified, can proceed with partial reports
  display("WARNING: Proceeding with $verified_reports/$total_reports reports")
  display("Missing reports: " + list(failed topics))
  proceed_to_step_5()

elif failed_reports == total_reports:
  # All reports failed even after retry
  display("ERROR: All research reports failed - cannot proceed to planning")
  escalate_to_user_with_detailed_error_report()
  exit_workflow()

else:
  # Less than half verified
  display("ERROR: Insufficient reports verified ($verified_reports/$total_reports)")
  display("Cannot proceed to planning with this few reports")
  escalate_to_user_with_detailed_error_report()
  exit_workflow()
```

**Update Workflow State**:

```yaml
workflow_state.research_phase_data.retry_summary = {
  "total_retries_attempted": 2,
  "successful_recoveries": 1,
  "failed_recoveries": 1,
  "recovery_methods": {
    "file_moved": 1,
    "agent_retry": 0,
    "metadata_fixed": 0,
    "retry_failed": 1,
    "escalated": 0
  },
  "retry_timestamp": "2025-10-13T14:40:00Z"
}

# Update each recovered report
workflow_state.research_reports[agent_index].recovery_method = "file_moved"
workflow_state.research_reports[agent_index].retry_count = 1
workflow_state.research_reports[agent_index].verified = true
```

**Loop Prevention**:

- **Max 1 retry per agent**: retry_count checked before reinvocation
- **Retry count tracked**: Stored in workflow_state.research_reports[].retry_count
- **Replan history logged**: For audit trail (if integrated with adaptive planning)
- **User escalation**: When limit exceeded or non-retryable errors

**Benefits of Intelligent Retry**:

- **Path Mismatch Recovery**: Automatically corrects Report 004 issue by moving files
- **Targeted Retry**: Only retry actually failed agents, not all agents
- **Loop Prevention**: Max 1 retry limit prevents infinite retry cycles
- **Preserves Parallelism**: Retries can still be parallel if multiple agents failed
- **Graceful Degradation**: Can proceed with partial reports if majority verified
- **Comprehensive Logging**: All retry attempts logged for debugging

Proceed to Step 5 after retry phase completes (regardless of results, but note status).

#### Step 5: Save Research Checkpoint

SAVE workflow checkpoint after research phase completion.

**EXECUTE NOW**:

USE the checkpoint utility to save research phase state:

```bash
# Source checkpoint utilities
source .claude/lib/checkpoint-utils.sh

# Prepare checkpoint data
CHECKPOINT_DATA=$(cat <<EOF
{
  "workflow_type": "orchestrate",
  "project_name": "${PROJECT_NAME}",
  "workflow_description": "${USER_WORKFLOW_DESCRIPTION}",
  "status": "research_complete",
  "current_phase": "research",
  "completed_phases": ["research"],
  "workflow_state": {
    "research_topics": ${RESEARCH_TOPICS_JSON},
    "research_reports": ${RESEARCH_REPORTS_JSON},
    "project_name": "${PROJECT_NAME}",
    "topic_slugs": ${TOPIC_SLUGS_JSON},
    "thinking_mode": "${THINKING_MODE}",
    "complexity_score": ${COMPLEXITY_SCORE}
  },
  "performance_metrics": {
    "research_start_time": "${RESEARCH_START_TIME}",
    "research_end_time": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "parallel_agents_used": ${NUM_RESEARCH_AGENTS},
    "reports_created": ${NUM_REPORTS_CREATED}
  },
  "next_phase": "planning"
}
EOF
)

# Save checkpoint
CHECKPOINT_PATH=$(save_checkpoint "orchestrate" "${PROJECT_NAME}" "$CHECKPOINT_DATA")
echo "Checkpoint saved: $CHECKPOINT_PATH"
```

**Checkpoint Fields Explanation**:

- **workflow_type**: Always "orchestrate" for this command
- **project_name**: Generated in Step 3.5, used for checkpoint filename
- **workflow_description**: Original user request
- **status**: "research_complete" indicates research phase finished
- **current_phase**: "research" (phase just completed)
- **completed_phases**: Array of all completed phases (["research"] so far)
- **workflow_state**: Complete state including reports, topics, complexity
- **performance_metrics**: Timing data for performance analysis
- **next_phase**: "planning" (where to resume if interrupted)

**Benefits**:
- **Resumability**: Workflow can be resumed if interrupted
- **State Preservation**: All research outputs preserved
- **Performance Tracking**: Metrics for optimization analysis
- **Error Recovery**: Can rollback to pre-planning state if needed

Proceed to Step 6 only after checkpoint successfully saved.

#### Step 6: Research Phase Execution Verification

VERIFY all research phase execution requirements before proceeding to planning phase.

**EXECUTE NOW**: Check each requirement explicitly.

**VERIFICATION CHECKLIST**:

1. **Agent Invocation Verified**:
   - [ ] Task tool invoked for each research topic
   - [ ] All Task invocations sent in SINGLE message (parallel execution)
   - [ ] All agents completed successfully OR failed with clear error message
   - Verification: Review agent invocation message, count Task tool calls

2. **Report Files Created**:
   - [ ] Each successful agent created a report file
   - [ ] Report files exist at expected paths: specs/reports/{topic_slug}/NNN_*.md
   - [ ] Report numbering follows NNN format (001, 002, 003...)
   - Verification: Use Read tool to verify each report file exists and is readable

3. **Report Paths Collected**:
   - [ ] REPORT_PATH extracted from each agent output
   - [ ] Report paths stored in workflow_state.research_reports array
   - [ ] Number of paths matches number of successful agents
   - Verification: Print workflow_state.research_reports array contents

4. **Report Metadata Complete**:
   - [ ] Each report includes all required metadata fields
   - [ ] Specs Directory field present in each report
   - [ ] Topic field matches topic_slug from Step 3.5
   - Verification: Read first 20 lines of each report, check for metadata section

5. **Checkpoint Saved**:
   - [ ] Research checkpoint saved successfully
   - [ ] Checkpoint file exists at expected path
   - [ ] Checkpoint includes all research_reports paths
   - Verification: Use bash to verify checkpoint file exists

**Verification Commands**:

```bash
# Verify report files exist
for REPORT in "${RESEARCH_REPORTS[@]}"; do
  if [ -f "$REPORT" ]; then
    echo "✓ Report exists: $REPORT"
  else
    echo "✗ MISSING: $REPORT"
    VALIDATION_FAILED=true
  fi
done

# Verify checkpoint saved
CHECKPOINT_FILE=".claude/checkpoints/orchestrate_${PROJECT_NAME}_*.json"
if ls $CHECKPOINT_FILE 1>/dev/null 2>&1; then
  echo "✓ Checkpoint saved"
else
  echo "✗ Checkpoint missing"
  VALIDATION_FAILED=true
fi

# If validation failed
if [ "$VALIDATION_FAILED" = true ]; then
  echo "ERROR: Research phase validation failed"
  echo "Review errors above and retry failed steps"
  exit 1
fi
```

**If Validation Fails**:

- **Missing Report Files**:
  - Retry agent invocation for missing reports (max 1 retry)
  - If retry fails: Proceed with available reports, document missing reports

- **Invalid Metadata**:
  - Use Edit tool to correct metadata in report file
  - Ensure all required fields present

- **Checkpoint Save Failed**:
  - Retry checkpoint save operation
  - If persistent: Continue without checkpoint (note resumption not possible)

**DO NOT PROCEED** to planning phase until all validation checks pass (or failures are explicitly handled).

**Success Output**:

```
✓ Research Phase Complete

Research Topics Investigated: 3
- existing_patterns
- security_practices
- framework_implementations

Reports Created: 3
- specs/reports/existing_patterns/001_auth_patterns.md
- specs/reports/security_practices/001_best_practices.md
- specs/reports/framework_implementations/001_lua_auth.md

Checkpoint Saved: .claude/checkpoints/orchestrate_user_authentication_20251012_143022.json

Performance:
- Total Time: 3m 24s
- Parallel Agents: 3
- Time Saved vs Sequential: ~68%

Next Phase: Planning
```

**State Management**:

UPDATE workflow_state after research phase completes:

```yaml
workflow_state.current_phase = "planning"
workflow_state.execution_tracking.phase_start_times["research"] = [research start timestamp]
workflow_state.execution_tracking.phase_end_times["research"] = [current timestamp]
workflow_state.execution_tracking.agents_invoked += [number of research agents]
workflow_state.execution_tracking.files_created += [number of reports]
workflow_state.completed_phases.append("research")
workflow_state.context_preservation.research_reports = [array of report paths]
```

UPDATE TodoWrite to mark research complete and planning as next:

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
      "status": "in_progress",
      "activeForm": "Creating implementation plan"
    },
    // ... remaining todos unchanged ...
  ]
}
```

#### Step 7: Complete Research Phase Execution Example

**Full Workflow Example**: "Add user authentication with email and password"

**Step 1: Identify Research Topics**
```
Workflow: "Add user authentication with email and password"
Complexity Analysis: "add" (×1) + "authentication" (security) + ~8 files estimated
Complexity Score: 8 (Complex)

Research Topics Identified:
1. existing_patterns - Current authentication implementations in codebase
2. security_practices - Password hashing and session management (2025 standards)
3. framework_implementations - Lua-specific authentication libraries and patterns
```

**Step 1.5: Determine Thinking Mode**
```
Complexity Score: 8
Thinking Mode: "think hard" (score 7-9 = high complexity)
```

**Step 3.5: Generate Project Name and Topic Slugs**
```
Project Name: "user_authentication" (from "user authentication")

Topic Slugs:
1. "existing_patterns" (from "Current authentication implementations")
2. "security_practices" (from "Password hashing and session management")
3. "framework_implementations" (from "Lua-specific authentication libraries")
```

**Step 2: Launch Parallel Research Agents**
```
Invoking 3 research-specialist agents in parallel (single message):

Task {
  subagent_type: "general-purpose",
  description: "Research existing authentication patterns using research-specialist",
  prompt: "Read and follow: .claude/agents/research-specialist.md\n\n**Thinking Mode**: think hard\n\n# Research Task: Current Authentication Implementations\n\n[Full prompt with all placeholders substituted...]"
}

Task {
  subagent_type: "general-purpose",
  description: "Research security best practices using research-specialist",
  prompt: "Read and follow: .claude/agents/research-specialist.md\n\n**Thinking Mode**: think hard\n\n# Research Task: Password Hashing and Session Management Best Practices\n\n[Full prompt...]"
}

Task {
  subagent_type: "general-purpose",
  description: "Research Lua authentication libraries using research-specialist",
  prompt: "Read and follow: .claude/agents/research-specialist.md\n\n**Thinking Mode**: think hard\n\n# Research Task: Lua-Specific Authentication Libraries\n\n[Full prompt...]"
}
```

**Step 3a: Monitor Execution**
```
[Agent 1: existing_patterns] PROGRESS: Searching codebase for auth implementations...
[Agent 2: security_practices] PROGRESS: Searching for 2025 password hashing standards...
[Agent 3: framework_implementations] PROGRESS: Researching Lua auth libraries...
[Agent 1: existing_patterns] PROGRESS: Found 12 files, analyzing patterns...
[Agent 2: security_practices] PROGRESS: Analyzing Argon2 vs bcrypt recommendations...
[Agent 3: framework_implementations] PROGRESS: Comparing lua-resty-session vs custom...
[Agent 1: existing_patterns] PROGRESS: Creating report file...
[Agent 2: security_practices] PROGRESS: Creating report file...
[Agent 3: framework_implementations] PROGRESS: Creating report file...
[Agent 1: existing_patterns] PROGRESS: Research complete.
[Agent 2: security_practices] PROGRESS: Research complete.
[Agent 3: framework_implementations] PROGRESS: Research complete.

All agents completed in 3m 24s (sequential would be ~9m 30s)
```

**Step 4: Collect Report Paths**
```
Agent 1 Output: "REPORT_PATH: specs/reports/existing_patterns/001_auth_patterns.md"
Agent 2 Output: "REPORT_PATH: specs/reports/security_practices/001_best_practices.md"
Agent 3 Output: "REPORT_PATH: specs/reports/framework_implementations/001_lua_auth.md"

Workflow State Updated:
{
  "research_reports": [
    "specs/reports/existing_patterns/001_auth_patterns.md",
    "specs/reports/security_practices/001_best_practices.md",
    "specs/reports/framework_implementations/001_lua_auth.md"
  ]
}
```

**Step 5: Save Checkpoint**
```
Checkpoint saved: .claude/checkpoints/orchestrate_user_authentication_20251012_143022.json

Checkpoint contents:
{
  "workflow_type": "orchestrate",
  "project_name": "user_authentication",
  "status": "research_complete",
  "current_phase": "research",
  "workflow_state": {
    "research_reports": [...],
    "thinking_mode": "think hard",
    "complexity_score": 8
  },
  "next_phase": "planning"
}
```

**Step 6: Validation**
```
✓ 3 Task tool invocations sent in single message
✓ All 3 agents completed successfully
✓ 3 report files created and validated
✓ 3 report paths collected in workflow_state
✓ Checkpoint saved successfully

Research Phase Complete - Ready for Planning Phase
```

This example demonstrates the complete execution flow from user request to validated research reports.

#### Troubleshooting: Research Phase Common Issues

##### Issue 1: Reports Created in Wrong Location (Path Inconsistency)

**Symptom**: Research agents complete successfully but reports not found at expected location.

**Root Cause**: Agents received RELATIVE paths and interpreted them from different base directories.

**Example**:
```
Expected: /home/benjamin/.config/.claude/specs/reports/orchestrate_improvements/001_report.md
Actual:   /home/benjamin/.config/specs/reports/orchestrate_improvements/001_report.md
          (missing .claude/ subdirectory)
```

**Diagnosis**:
```bash
# Search for report file in multiple locations
find /home/benjamin/.config -name "001_*.md" -path "*/specs/reports/orchestrate_improvements/*" 2>/dev/null

# Check agent prompts to verify absolute paths were provided
grep "REPORT_PATH:" .claude/checkpoints/*.json
```

**Resolution**:
1. **Prevention** (CRITICAL): Always provide ABSOLUTE paths in agent prompts (see Step 2)
2. **Recovery**: If reports exist at wrong location:
   ```bash
   # Move reports to correct location
   EXPECTED="/home/benjamin/.config/.claude/specs/reports/topic"
   ACTUAL="/home/benjamin/.config/specs/reports/topic"

   mkdir -p "$EXPECTED"
   mv "$ACTUAL"/*.md "$EXPECTED/"
   ```
3. **Verification**: Re-run Step 4 verification to confirm all reports at expected locations

**Prevention Checklist**:
- [ ] Step 2 generates ABSOLUTE paths (starts with `/home/...`)
- [ ] Agent prompts contain `[ABSOLUTE_REPORT_PATH]` placeholder
- [ ] No relative paths (e.g., `specs/...`) in agent prompts
- [ ] Directory exists before agents invoked (`mkdir -p`)

##### Issue 2: Report Metadata Incomplete

**Symptom**: Report file exists but missing required metadata fields.

**Root Cause**: Agent didn't follow report structure template correctly.

**Diagnosis**:
```bash
# Check report has metadata section
head -20 /path/to/report.md | grep -E "^## Metadata|^- \*\*Date\*\*:|^- \*\*Topic\*\*:"
```

**Resolution**:
```bash
# Edit report to add missing metadata
# Use Edit tool to add fields at top of file
```

**Prevention**: Research agent prompt template (Step 3) includes complete metadata template.

##### Issue 3: Agent Failed to Create Report File

**Symptom**: Agent completed but no REPORT_PATH in output and no file created.

**Root Cause**: Agent returned summary instead of creating file, or Write tool failed.

**Diagnosis**:
- Check agent output for REPORT_PATH: marker
- Check agent output for Write tool invocation
- Check agent output for errors (permission denied, disk full)

**Resolution**:
1. **Retry agent invocation** with emphasized file creation requirement:
   ```markdown
   CRITICAL: You MUST use the Write tool to create a report file at:
   [ABSOLUTE_REPORT_PATH]

   DO NOT return only a summary. The report file must be created.
   ```
2. **Verify directory permissions**:
   ```bash
   ls -ld .claude/specs/reports/
   mkdir -p .claude/specs/reports/topic_slug
   ```

##### Issue 4: Multiple Agents Create Same Report Number

**Symptom**: Agents overwrite each other's reports, final count doesn't match agent count.

**Root Cause**: Report numbers calculated before agents start, but agents run in parallel and race to create files.

**Resolution**:
- **Not an issue**: Orchestrator calculates report numbers in Step 2 BEFORE invoking agents
- Each agent receives unique report number in its prompt
- Parallel execution safe because paths are pre-allocated

**If this still occurs**:
- Check Step 2 implementation: Each agent must get unique `REPORT_NUM`
- Verify agents don't recalculate report numbers themselves

##### Issue 5: Research Phase Takes Too Long

**Symptom**: Research agents running for >10 minutes total.

**Diagnosis**:
- Check if agents invoked in parallel (single message) or sequential (multiple messages)
- Check agent thinking modes (too complex for simple workflows)

**Resolution**:
1. **Verify parallel execution**: All Task invocations in single message (Step 2.5)
2. **Reduce thinking mode complexity**: Recalculate complexity score (Step 1.5)
3. **Reduce research scope**: Fewer topics (2-3 instead of 4)
4. **Check agent resources**: Agents may be waiting for tools (Grep on large codebase)

**Expected Timings**:
- Simple research (2 agents): 2-3 minutes parallel
- Medium research (3 agents): 3-5 minutes parallel
- Complex research (4 agents): 5-8 minutes parallel

##### Issue 6: All Research Agents Failed

**Symptom**: All agents return errors or no reports created.

**Possible Causes**:
1. **Specs directory doesn't exist**:
   ```bash
   mkdir -p .claude/specs/reports
   ```
2. **Permission denied**:
   ```bash
   ls -ld .claude/specs/reports
   chmod u+w .claude/specs/reports
   ```
3. **Agent behavioral guidelines missing**:
   ```bash
   ls -l .claude/agents/research-specialist.md
   ```
4. **Invalid agent prompts**: Check for placeholder substitution errors

**Resolution**: Check each cause systematically, fix infrastructure issues, retry research phase.

**Escalation**: If all agents fail after retry and infrastructure verified, escalate to user with detailed error report.

### Planning Phase (Sequential Execution)

#### Step 1: Prepare Planning Context

EXTRACT necessary context from completed workflow phases for the planning agent.

**EXECUTE NOW**:

1. READ workflow_state to identify completed phases and available artifacts
2. EXTRACT research report paths from workflow_state.research_reports array (if research phase completed)
3. EXTRACT user's original workflow description
4. EXTRACT project_name and thinking_mode from workflow_state
5. VERIFY all referenced files exist before passing to planning agent

**Context Sources**:

**From Research Phase** (if research completed):
```yaml
research_context:
  report_paths: workflow_state.research_reports  # Array of file paths only
  topics: workflow_state.topic_slugs  # Topics investigated
  # DO NOT read report content - agent will use Read tool selectively
```

**Example**:
```yaml
research_context:
  report_paths: [
    "specs/reports/existing_patterns/001_auth_patterns.md",
    "specs/reports/security_practices/001_best_practices.md",
    "specs/reports/framework_implementations/001_lua_auth.md"
  ]
  topics: ["existing_patterns", "security_practices", "framework_implementations"]
```

**From User Request**:
```yaml
user_context:
  workflow_description: workflow_state.workflow_description  # Original user request
  project_name: workflow_state.project_name  # Generated in research phase
  workflow_type: workflow_state.workflow_type  # feature|refactor|debug|investigation
  thinking_mode: workflow_state.thinking_mode  # Determined in research phase Step 1.5
```

**From Project Standards**:
```yaml
standards_reference:
  claude_md_path: "/home/benjamin/.config/CLAUDE.md"
  # Agent will read this file for project-specific standards
```

**Context Injection Strategy**:
- Provide report file paths ONLY (not full summaries) - agent uses Read tool to access content selectively
- Include user's original request for full context understanding
- Reference CLAUDE.md path for project standards
- Include thinking_mode from research phase for consistency
- NO orchestration details or phase routing logic passed to agent

**Context Validation Checklist**:
- [ ] Research report paths exist (if research phase completed)
- [ ] User workflow description is clear and complete
- [ ] Project name is set correctly
- [ ] Thinking mode is specified (if applicable)
- [ ] CLAUDE.md path is valid

#### Step 2: Generate Planning Agent Prompt

GENERATE the complete prompt for the plan-architect agent using the template below.

**EXECUTE NOW**:

1. SUBSTITUTE all placeholders in the template with actual values from Step 1
2. VERIFY all research report paths are included (if research phase completed)
3. VERIFY thinking_mode is prepended if applicable
4. CONSTRUCT complete prompt string for Task tool invocation

**Placeholders to Substitute**:
- [THINKING_MODE]: Value from workflow_state.thinking_mode (e.g., "think hard") or empty if not set
- [FEATURE_NAME]: Extracted from workflow_description or project_name
- [USER_WORKFLOW_DESCRIPTION]: Original user request from workflow_state
- [REPORT_PATHS]: Array of research report paths with descriptions
- [PROJECT_STANDARDS_PATH]: Path to CLAUDE.md

**Complete Prompt Template**:

```markdown
[THINKING_MODE_LINE]

# Planning Task: Create Implementation Plan for [FEATURE_NAME]

## Context

### User Request
[Original workflow description]

### Research Reports
[If research phase completed, provide report paths:]

Available Research Reports:
1. **Existing Patterns**
   - Path: specs/reports/existing_patterns/001_auth_patterns.md
   - Topic: Current implementation analysis
   - Use Read tool to access full findings

2. **Security Practices**
   - Path: specs/reports/security_practices/001_best_practices.md
   - Topic: Industry standards (2025)
   - Use Read tool to access recommendations

3. **Framework Implementations**
   - Path: specs/reports/framework_implementations/001_lua_auth.md
   - Topic: Implementation options and trade-offs
   - Use Read tool to access detailed comparisons

**Instructions**: Read relevant reports selectively based on planning needs. All reports should be referenced in the plan metadata's "Research Reports" section.

[If no research: "Direct implementation - no prior research reports"]

### Project Standards
Reference standards at: /home/benjamin/.config/CLAUDE.md

## Objective
Create a comprehensive, phased implementation plan for [feature/task] that:
- Synthesizes research findings into actionable steps
- Defines clear implementation phases with tasks
- Establishes testing strategy for each phase
- Follows project coding standards and conventions

## Requirements

### Plan Structure
Use the /plan command to generate a structured implementation plan:

```bash
/plan [feature description] [research-report-path-if-exists]
```

The plan should include:
- Metadata (date, feature, scope, standards file, research reports)
- Overview and success criteria
- Technical design decisions
- Implementation phases with specific tasks
- Testing strategy
- Documentation requirements
- Risk assessment

### Task Specificity
Each task should:
- Reference specific files to create/modify
- Include line number ranges where applicable
- Specify testing requirements
- Define validation criteria

### Context from Research
[If research completed]
Incorporate these key findings:
- [Insight 1]
- [Insight 2]
- [Insight 3]

Recommended approach: [From research synthesis]

## Expected Output

**Primary Output**: Path to generated implementation plan
- Format: `specs/plans/NNN_feature_name.md`
- Location: Most appropriate directory in project structure
- **Note**: The /plan command will automatically:
  - Read specs directory from research reports (if provided)
  - Check/register in `.claude/SPECS.md`
  - Include "Specs Directory" in plan metadata

**Secondary Output**: Brief summary of plan
- Number of phases
- Estimated complexity
- Key technical decisions

## Success Criteria
- Plan follows project standards (CLAUDE.md)
- Phases are well-defined and testable
- Tasks are specific and actionable
- Testing strategy is comprehensive
- Plan integrates research recommendations

## Error Handling
- If /plan command fails: Report error and provide manual planning guidance
- If standards unclear: Make reasonable assumptions following best practices
- If research conflicts: Document trade-offs and chosen approach
```

End of prompt template.

**Prompt Verification Checklist**:
- [ ] Thinking mode prepended if applicable (check workflow_state.thinking_mode)
- [ ] Feature name substituted correctly
- [ ] User workflow description included
- [ ] Research report paths listed (if research phase completed) or "no prior research" noted
- [ ] Project standards path (/home/benjamin/.config/CLAUDE.md) included
- [ ] Expected output format specified (plan file path + summary)
- [ ] Success criteria clearly defined

#### Step 3: Invoke Planning Agent

**EXECUTE NOW**: USE the Task tool to invoke the plan-architect agent.

SEND this Task tool invocation NOW with these exact parameters:

```json
{
  "subagent_type": "general-purpose",
  "description": "Create implementation plan for [FEATURE_NAME] using plan-architect protocol",
  "prompt": "Read and follow the behavioral guidelines from:\n/home/benjamin/.config/.claude/agents/plan-architect.md\n\nYou are acting as a Plan Architect with the tools and constraints defined in that file.\n\n[COMPLETE_PROMPT_FROM_STEP_2]"
}
```

**Substitutions**:
- [FEATURE_NAME]: Feature name from workflow_state.project_name
- [COMPLETE_PROMPT_FROM_STEP_2]: Full prompt string generated in Step 2 (with all placeholders already substituted)

**Execution Details**:
- This is a SINGLE agent invocation (sequential execution, not parallel)
- Agent has full access to project files for analysis
- Agent can invoke /plan slash command
- Agent will return plan file path and summary

**WAIT** for planning agent to complete before proceeding to Step 4.

**Monitoring**:
- **Progress Streaming**: WATCH for `PROGRESS: <message>` markers in agent output
  - Examples: `PROGRESS: Analyzing requirements...`, `PROGRESS: Designing 4 phases...`
  - DISPLAY progress updates to user in real-time
- Track planning progress through agent updates
- Watch for plan file creation notification

#### Step 4: Extract Plan Path and Validation

EXTRACT plan file path from planning agent output and VALIDATE plan quality.

**EXECUTE NOW**:

1. PARSE agent output to extract plan file path
2. EXTRACT plan metadata (number, phases, complexity)
3. VALIDATE plan file exists and is well-formed
4. VERIFY plan meets quality requirements

**Path Extraction Algorithm**:

From planning agent output:

```
Step 1: SEARCH for plan path pattern
- Pattern: "specs/plans/NNN_*.md" or "PLAN_PATH: specs/plans/..."
- Extract: Full file path

Step 2: PARSE plan metadata
- Plan number: NNN (from filename)
- Read file metadata section
- Extract: phase_count, complexity, research_reports

Step 3: CONSTRUCT plan data structure
plan_data = {
  path: "specs/plans/NNN_feature_name.md",
  number: NNN,
  phase_count: N,
  complexity: "Low|Medium|High"
}

Step 4: STORE in workflow_state
workflow_state.plan_path = plan_data.path
workflow_state.plan_number = plan_data.number
```

**Validation Bash Commands**:

```bash
# Verify plan file exists
PLAN_PATH="specs/plans/NNN_feature_name.md"
if [ -f "$PLAN_PATH" ]; then
  echo "✓ Plan file exists: $PLAN_PATH"
else
  echo "✗ Plan file missing: $PLAN_PATH"
  exit 1
fi

# Verify plan has required sections
REQUIRED_SECTIONS=("## Metadata" "## Overview" "## Implementation Phases" "## Testing Strategy")
for SECTION in "${REQUIRED_SECTIONS[@]}"; do
  if grep -q "$SECTION" "$PLAN_PATH"; then
    echo "✓ Section found: $SECTION"
  else
    echo "✗ Missing section: $SECTION"
    VALIDATION_FAILED=true
  fi
done

# Verify plan references research reports (if research phase completed)
if [ ${#RESEARCH_REPORTS[@]} -gt 0 ]; then
  if grep -q "Research Reports:" "$PLAN_PATH"; then
    echo "✓ Plan references research reports"
  else
    echo "⚠ Warning: Plan doesn't reference research reports"
  fi
fi
```

**Validation Checklist**:
- [ ] Plan file exists at expected path
- [ ] Plan file is readable (not empty, not corrupted)
- [ ] Plan includes required metadata fields (Date, Feature, Scope, Standards File)
- [ ] Plan has Implementation Phases section with numbered phases
- [ ] Plan includes Testing Strategy section
- [ ] Plan tasks reference specific files (not just abstract descriptions)
- [ ] Plan references research reports in metadata (if research phase completed)

**If Validation Fails**:
- **Missing File**: Check agent output for errors, retry planning agent invocation (max 1 retry)
- **Incomplete Plan**: Invoke planning agent again with clarification about missing sections
- **No File References**: Accept plan but note tasks may be less specific than desired
- **If Retry Fails**: Escalate to user with error details and partial plan (if exists)

#### Step 5: Save Planning Checkpoint

SAVE workflow checkpoint after planning phase completion.

**EXECUTE NOW**:

USE the checkpoint utility to save planning phase state:

```bash
# Source checkpoint utilities
source .claude/lib/checkpoint-utils.sh

# Prepare checkpoint data
CHECKPOINT_DATA=$(cat <<EOF
{
  "workflow_type": "orchestrate",
  "project_name": "${PROJECT_NAME}",
  "workflow_description": "${USER_WORKFLOW_DESCRIPTION}",
  "status": "plan_ready",
  "current_phase": "planning",
  "completed_phases": ["research", "planning"],
  "workflow_state": {
    "research_reports": ${RESEARCH_REPORTS_JSON},
    "plan_path": "${PLAN_PATH}",
    "plan_number": ${PLAN_NUMBER},
    "phase_count": ${PHASE_COUNT},
    "complexity": "${COMPLEXITY}",
    "thinking_mode": "${THINKING_MODE}"
  },
  "performance_metrics": {
    "research_time": "${RESEARCH_DURATION}",
    "planning_start_time": "${PLANNING_START_TIME}",
    "planning_end_time": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "planning_duration": "${PLANNING_DURATION}"
  },
  "next_phase": "implementation"
}
EOF
)

# Save checkpoint
CHECKPOINT_PATH=$(save_checkpoint "orchestrate" "${PROJECT_NAME}" "$CHECKPOINT_DATA")
echo "Checkpoint saved: $CHECKPOINT_PATH"
```

**Checkpoint Fields Explanation**:

- **workflow_type**: Always "orchestrate" for this command
- **project_name**: Generated in research phase Step 3.5
- **workflow_description**: Original user request
- **status**: "plan_ready" indicates planning phase complete
- **current_phase**: "planning" (phase just completed)
- **completed_phases**: Array of all completed phases (["research", "planning"] or just ["planning"] if research skipped)
- **workflow_state.plan_path**: Plan file path for implementation phase
- **workflow_state.plan_number**: Plan number (NNN) for reference
- **workflow_state.phase_count**: Number of implementation phases
- **workflow_state.complexity**: Plan complexity (Low|Medium|High)
- **performance_metrics**: Timing data for performance analysis
- **next_phase**: "implementation" (where to resume if interrupted)

**Context Update**:
- Store ONLY plan path in workflow_state, not plan content (agent will read file when needed)
- Mark planning phase as completed in completed_phases array
- Prepare workflow_state for implementation phase

**Benefits**:
- **Resumability**: Can resume from implementation phase if interrupted
- **State Preservation**: Plan path and metadata preserved
- **Performance Tracking**: Planning duration recorded for metrics
- **Error Recovery**: Can rollback to pre-implementation state if needed

Proceed to Step 6 only after checkpoint successfully saved.

#### Step 6: Planning Phase Completion

OUTPUT completion status to user with comprehensive details.

**EXECUTE NOW**:

1. VERIFY all planning phase success criteria met
2. FORMAT completion message with plan details
3. DISPLAY status to user
4. CONFIRM transition to implementation phase

**Success Criteria Verification**:
- [ ] Plan file created successfully
- [ ] Plan includes all required sections (Metadata, Phases, Testing)
- [ ] Plan metadata complete (Date, Scope, Standards)
- [ ] Plan references research reports (if research phase completed)
- [ ] Checkpoint saved successfully
- [ ] workflow_state updated with plan_path

**Completion Message Format**:

```markdown
✓ Planning Phase Complete

**Plan Created**: specs/plans/NNN_feature_name.md

**Plan Details**:
- Plan Number: NNN
- Implementation Phases: N
- Complexity: Medium
- Estimated Hours: X-Y

[If research phase completed]
**Incorporating Research From**:
- specs/reports/existing_patterns/001_auth_patterns.md
- specs/reports/security_practices/001_best_practices.md
- specs/reports/framework_implementations/001_lua_auth.md

**Performance**:
- Planning Time: X minutes Y seconds

**Checkpoint Saved**: .claude/checkpoints/orchestrate_[project_name]_[timestamp].json

**Next Phase**: Implementation
```

**State Management**:

UPDATE workflow_state after planning phase completes:

```yaml
workflow_state.current_phase = "implementation"
workflow_state.execution_tracking.phase_start_times["planning"] = [planning start timestamp]
workflow_state.execution_tracking.phase_end_times["planning"] = [current timestamp]
workflow_state.execution_tracking.agents_invoked += 1  # plan-architect agent
workflow_state.execution_tracking.files_created += 1  # plan file
workflow_state.completed_phases.append("planning")
workflow_state.context_preservation.plan_path = [extracted plan path]
```

UPDATE TodoWrite to mark planning complete and implementation as next:

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
      "status": "in_progress",
      "activeForm": "Implementing features with testing"
    },
    // ... remaining todos unchanged ...
  ]
}
```

**Transition Confirmation**:

After displaying completion message, confirm workflow will proceed to implementation phase:
```
→ Proceeding to Implementation Phase
```

Proceed immediately to Implementation Phase Step 1 (Prepare Implementation Context).

#### Step 7: Complete Planning Phase Execution Example

**Full Workflow Example**: "Add user authentication with email and password" (continuing from completed Research Phase)

**Context from Research Phase**:
```
Research Phase Completed:
- 3 research reports created
- Project name: "user_authentication"
- Thinking mode: "think hard"
- Complexity score: 8
```

**Step 1: Prepare Planning Context**
```
EXTRACT context from workflow_state:

research_context:
  report_paths: [
    "specs/reports/existing_patterns/001_auth_patterns.md",
    "specs/reports/security_practices/001_best_practices.md",
    "specs/reports/framework_implementations/001_lua_auth.md"
  ]
  topics: ["existing_patterns", "security_practices", "framework_implementations"]

user_context:
  workflow_description: "Add user authentication with email and password"
  project_name: "user_authentication"
  workflow_type: "feature"
  thinking_mode: "think hard"

standards_reference:
  claude_md_path: "/home/benjamin/.config/CLAUDE.md"

Context validation:
✓ 3 research report paths exist
✓ User workflow description clear
✓ Project name set: user_authentication
✓ Thinking mode specified: think hard
✓ CLAUDE.md path valid
```

**Step 2: Generate Planning Agent Prompt**
```
SUBSTITUTE placeholders in template:

- [THINKING_MODE]: "**Thinking Mode**: think hard"
- [FEATURE_NAME]: "User Authentication"
- [USER_WORKFLOW_DESCRIPTION]: "Add user authentication with email and password"
- [REPORT_PATHS]:
  1. specs/reports/existing_patterns/001_auth_patterns.md - Current auth patterns
  2. specs/reports/security_practices/001_best_practices.md - Security standards (2025)
  3. specs/reports/framework_implementations/001_lua_auth.md - Lua auth libraries
- [PROJECT_STANDARDS_PATH]: /home/benjamin/.config/CLAUDE.md

Prompt verification:
✓ Thinking mode prepended
✓ Feature name substituted
✓ User workflow description included
✓ All 3 research reports listed
✓ Project standards path included
✓ Expected output format specified
```

**Step 3: Invoke Planning Agent**
```
Task tool invocation sent:

{
  "subagent_type": "general-purpose",
  "description": "Create implementation plan for User Authentication using plan-architect protocol",
  "prompt": "Read and follow: .claude/agents/plan-architect.md\n\n**Thinking Mode**: think hard\n\n# Planning Task: Create Implementation Plan for User Authentication\n\n[Complete prompt with all substitutions...]"
}

Agent execution:
PROGRESS: Reading research reports...
PROGRESS: Analyzing security requirements from reports...
PROGRESS: Designing 4 implementation phases...
PROGRESS: Creating plan file...
PROGRESS: Planning complete.

Agent completed in 2m 45s
```

**Step 4: Extract Plan Path and Validation**
```
Agent output:
"I've created a comprehensive implementation plan at specs/plans/013_user_authentication.md.
The plan includes 4 phases with approximately 12-15 hours of implementation work..."

Extracted plan data:
{
  path: "specs/plans/013_user_authentication.md",
  number: "013",
  phase_count: 4,
  complexity: "Medium"
}

Validation commands executed:
✓ Plan file exists: specs/plans/013_user_authentication.md
✓ Section found: ## Metadata
✓ Section found: ## Overview
✓ Section found: ## Implementation Phases
✓ Section found: ## Testing Strategy
✓ Plan references research reports

All validations passed
```

**Step 5: Save Planning Checkpoint**
```
Checkpoint saved: .claude/checkpoints/orchestrate_user_authentication_20251012_145810.json

Checkpoint contents:
{
  "workflow_type": "orchestrate",
  "project_name": "user_authentication",
  "status": "plan_ready",
  "current_phase": "planning",
  "completed_phases": ["research", "planning"],
  "workflow_state": {
    "research_reports": [
      "specs/reports/existing_patterns/001_auth_patterns.md",
      "specs/reports/security_practices/001_best_practices.md",
      "specs/reports/framework_implementations/001_lua_auth.md"
    ],
    "plan_path": "specs/plans/013_user_authentication.md",
    "plan_number": "013",
    "phase_count": 4,
    "complexity": "Medium",
    "thinking_mode": "think hard"
  },
  "performance_metrics": {
    "research_time": "3m 24s",
    "planning_duration": "2m 45s"
  },
  "next_phase": "implementation"
}
```

**Step 6: Planning Phase Completion**
```
✓ Planning Phase Complete

**Plan Created**: specs/plans/013_user_authentication.md

**Plan Details**:
- Plan Number: 013
- Implementation Phases: 4
- Complexity: Medium
- Estimated Hours: 12-15

**Incorporating Research From**:
- specs/reports/existing_patterns/001_auth_patterns.md
- specs/reports/security_practices/001_best_practices.md
- specs/reports/framework_implementations/001_lua_auth.md

**Performance**:
- Planning Time: 2 minutes 45 seconds

**Checkpoint Saved**: .claude/checkpoints/orchestrate_user_authentication_20251012_145810.json

**Next Phase**: Implementation

→ Proceeding to Implementation Phase
```

This example demonstrates the complete planning phase execution flow from research output to validated implementation plan.

### Implementation Phase (Adaptive Execution)

#### Step 1: Extract Implementation Context

EXTRACT plan path and metadata from planning phase output to prepare for implementation agent invocation.

**EXECUTE NOW: Extract Context from Planning Phase**

From the planning phase checkpoint (saved in Step 5 of Planning Phase), EXTRACT:

1. **Plan File Path**:
   - Variable: plan_path
   - Example: "specs/plans/042_user_authentication.md"
   - Source: planning_phase_checkpoint.outputs.plan_path

2. **Plan Metadata**:
   - Plan number: Extract from filename (NNN prefix)
   - Phase count: Read from plan file metadata
   - Complexity level: Read from plan metadata or estimate

3. **Store in workflow_state**:
   ```yaml
   workflow_state.implementation_context:
     plan_path: "[extracted_path]"
     plan_number: "[NNN]"
     phase_count: "[N]"
     complexity: "[Low|Medium|High]"
   ```

**Context Extraction Commands**:
```bash
# Extract plan path from checkpoint
PLAN_PATH=$(jq -r '.outputs.plan_path' < checkpoint_plan_ready.json)

# Extract plan number from filename
PLAN_NUMBER=$(basename "$PLAN_PATH" | grep -oP '^\d+')

# Read phase count from plan file
PHASE_COUNT=$(grep -c "^### Phase" "$PLAN_PATH")

# Read complexity from metadata
COMPLEXITY=$(grep "^- \*\*Complexity\*\*:" "$PLAN_PATH" | cut -d: -f2 | tr -d ' ')
```

**Validation**:
- Verify plan file exists: Use Read tool to check plan_path
- Verify plan is complete: Check for all required sections (phases, tasks, testing)
- If validation fails: Report error and halt workflow

**Verification Checklist**:
- [ ] Plan path extracted and validated (file exists)
- [ ] Plan number parsed correctly (3-digit format)
- [ ] Phase count matches plan structure
- [ ] Complexity level identified or defaulted

#### Step 2: Build Implementation Agent Prompt

**EXECUTE NOW: Construct Code-Writer Prompt**

BUILD the complete prompt for the code-writer agent using this template:

**Prompt Template** (use verbatim, substituting bracketed variables):

```
Read and follow the behavioral guidelines from:
/home/benjamin/.config/.claude/agents/code-writer.md

You are acting as a Code Writer Agent with the tools and constraints
defined in that file.

# Implementation Task: Execute Implementation Plan

## Context

### Implementation Plan
Plan file: [plan_path]
Plan number: [plan_number]
Total phases: [phase_count]
Complexity: [complexity]

Read the complete plan to understand:
- All implementation phases
- Specific tasks for each phase
- Testing requirements per phase
- Success criteria

### Project Standards
Reference standards at: /home/benjamin/.config/CLAUDE.md

Apply these standards during code generation:
- Indentation: 2 spaces, expandtab
- Naming: snake_case for variables/functions
- Error handling: Use pcall for Lua, try-catch for others
- Line length: ~100 characters soft limit
- Documentation: Comment non-obvious logic

## Objective

Execute the implementation plan phase by phase using the /implement command.

## Requirements

### Execution Approach

Use the /implement command to execute the plan:

```bash
/implement [plan_path]
```

The /implement command will:
- Parse plan and identify all phases with dependencies
- Execute phases in dependency order (parallel where possible)
- Run tests after each phase
- Create git commit for each completed phase
- Handle errors with automatic retry (max 3 attempts)
- Update plan with completion markers

### Phase-by-Phase Execution

For each phase, /implement will:
1. Display phase name and tasks
2. Implement all tasks in phase following project standards
3. Run phase-specific tests
4. Validate all tests pass
5. Create structured git commit
6. Save checkpoint before next phase

### Testing Requirements

**CRITICAL**: Tests must run after EACH phase, not just at the end.

- Run tests after completing each phase
- Tests must pass before proceeding to next phase
- If tests fail: STOP and report (do not continue to next phase)
- Test commands: Use commands specified in plan or project CLAUDE.md

### Error Handling

- Automatic retry for transient errors (max 3 attempts per operation)
- If tests fail: DO NOT proceed to next phase
- Report test failures with detailed error messages and file locations
- Preserve all completed work even if later phase fails
- Save checkpoint at failure point for debugging

## Expected Output

**SUCCESS CASE** - All Phases Complete:
```
TESTS_PASSING: true
PHASES_COMPLETED: [N]/[N]
FILES_MODIFIED: [file1.ext, file2.ext, ...]
GIT_COMMITS: [hash1, hash2, ...]
IMPLEMENTATION_STATUS: success
```

**FAILURE CASE** - Tests Failed:
```
TESTS_PASSING: false
PHASES_COMPLETED: [M]/[N]
FAILED_PHASE: [N]
ERROR_MESSAGE: [Test failure details with file locations]
FILES_MODIFIED: [files changed before failure]
IMPLEMENTATION_STATUS: failed
```

## Output Format Requirements

**REQUIRED**: Structure your final output to include these exact markers so the orchestrator can parse results:

1. Test status line: `TESTS_PASSING: true` or `TESTS_PASSING: false`
2. Phases completed line: `PHASES_COMPLETED: M/N`
3. If failed, include: `FAILED_PHASE: N` and `ERROR_MESSAGE: [details]`
4. File changes line: `FILES_MODIFIED: [array of file paths]`
5. Git commits line: `GIT_COMMITS: [array of commit hashes]`

## Success Criteria

- All plan phases executed successfully (N/N)
- All tests passing after final phase
- Code follows project standards (verified before each commit)
- Git commits created for each phase with structured messages
- No merge conflicts or build errors
- Implementation status clearly indicated

## Error Handling

- **Timeout errors**: Retry with extended timeout (up to 600000ms)
- **Test failures**: STOP immediately, report phase and error details
- **Tool access errors**: Retry with available tools (Read/Write/Edit fallback)
- **Persistent errors**: Report for debugging (do not skip or ignore)
```

**Variable Substitution**:
Replace these variables from workflow_state:
- [plan_path]: workflow_state.implementation_context.plan_path
- [plan_number]: workflow_state.implementation_context.plan_number
- [phase_count]: workflow_state.implementation_context.phase_count
- [complexity]: workflow_state.implementation_context.complexity

**Store Prompt**:
```yaml
workflow_state.implementation_prompt: "[generated_prompt]"
```

#### Step 3: Invoke Code-Writer Agent for Implementation

**EXECUTE NOW: USE Task Tool to Invoke Code-Writer Agent**

Invoke the code-writer agent NOW using the Task tool with these exact parameters:

**Task Tool Invocation** (execute this call):

```json
{
  "subagent_type": "general-purpose",
  "description": "Execute implementation plan [plan_number] using code-writer protocol",
  "timeout": 600000,
  "prompt": "[workflow_state.implementation_prompt from Step 2]"
}
```

**Timeout Justification**: 600000ms (10 minutes) allows for:
- Multi-phase implementation (4-8 phases typical)
- Test execution after each phase
- Git commit creation per phase
- Automatic error retry (up to 3 attempts)
- Complex implementations with many files

**Invocation Instructions**:
1. USE the Task tool (not SlashCommand or Bash)
2. SET subagent_type to "general-purpose"
3. SET timeout to 600000 (not default 120000)
4. PASS complete prompt from Step 2 verbatim
5. WAIT for agent completion (do not proceed to Step 4 until done)

**While Waiting for Agent**:

Monitor agent output for PROGRESS markers:
- `PROGRESS: Implementing Phase N: [phase name]...`
- `PROGRESS: Running tests for Phase N...`
- `PROGRESS: Creating git commit for Phase N...`
- `PROGRESS: All tests passing, proceeding to Phase N+1...`

Display progress updates to user in real-time for transparency.

**After Agent Completes**:
Store complete agent output for parsing in Step 4:
```yaml
workflow_state.implementation_output: "[agent_output]"
```

**Verification Checklist**:
- [ ] Task tool invoked (not just described)
- [ ] Timeout set to 600000ms (extended for complex implementations)
- [ ] Agent type set to "general-purpose"
- [ ] Complete prompt passed to agent
- [ ] Agent output captured for status extraction

#### Step 4: Parse Implementation Results and Test Status

**EXECUTE NOW: Extract Status from Agent Output**

PARSE the agent output (workflow_state.implementation_output) to extract implementation results.

**Status Extraction Algorithm**:

```python
# Pseudo-code for status extraction

# 1. Extract test status
if "TESTS_PASSING: true" in agent_output:
    tests_passing = True
elif "TESTS_PASSING: false" in agent_output:
    tests_passing = False
else:
    # Fallback: search for test result indicators
    if "all tests pass" in agent_output.lower() or "✓ all passing" in agent_output.lower():
        tests_passing = True
    else:
        tests_passing = False

# 2. Extract phases completed
match = re.search(r'PHASES_COMPLETED: (\d+)/(\d+)', agent_output)
if match:
    completed = int(match.group(1))
    total = int(match.group(2))
else:
    # Fallback: count completed phase markers
    completed = agent_output.count('[COMPLETED]')
    total = workflow_state.implementation_context.phase_count

# 3. Extract file changes
match = re.search(r'FILES_MODIFIED: \[(.*?)\]', agent_output)
if match:
    files_modified = match.group(1).split(', ')
else:
    # Fallback: empty list
    files_modified = []

# 4. Extract git commits
match = re.search(r'GIT_COMMITS: \[(.*?)\]', agent_output)
if match:
    git_commits = match.group(1).split(', ')
else:
    git_commits = []

# 5. If tests failed, extract failure details
if not tests_passing:
    match = re.search(r'FAILED_PHASE: (\d+)', agent_output)
    failed_phase = int(match.group(1)) if match else None

    match = re.search(r'ERROR_MESSAGE: (.*?)(?:\n|$)', agent_output)
    error_message = match.group(1) if match else "Unknown error"
```

**Concrete Extraction Commands**:

```bash
# Extract test status
TESTS_PASSING=$(echo "$AGENT_OUTPUT" | grep -oP 'TESTS_PASSING: \K(true|false)' || echo "false")

# Extract phases completed
PHASES_COMPLETED=$(echo "$AGENT_OUTPUT" | grep -oP 'PHASES_COMPLETED: \K\d+/\d+' || echo "0/0")

# Extract modified files
FILES_MODIFIED=$(echo "$AGENT_OUTPUT" | grep -oP 'FILES_MODIFIED: \[\K[^\]]+' || echo "")

# Extract git commits
GIT_COMMITS=$(echo "$AGENT_OUTPUT" | grep -oP 'GIT_COMMITS: \[\K[^\]]+' || echo "")

# If tests failed, extract failure details
if [ "$TESTS_PASSING" = "false" ]; then
    FAILED_PHASE=$(echo "$AGENT_OUTPUT" | grep -oP 'FAILED_PHASE: \K\d+' || echo "unknown")
    ERROR_MESSAGE=$(echo "$AGENT_OUTPUT" | grep -oP 'ERROR_MESSAGE: \K.*' || echo "Unknown error")
fi
```

**Store Results in Workflow State**:

```yaml
workflow_state.implementation_status:
  tests_passing: [true|false]
  phases_completed: "[M]/[N]"
  files_modified: [array]
  git_commits: [array]
  status: "success|failed"

# If failed:
workflow_state.implementation_failure:
  failed_phase: [N]
  error_message: "[details]"
  partial_completion: true
```

**Validation Checklist**:
- [ ] Test status clearly extracted (true or false, not ambiguous)
- [ ] Phase completion count matches plan structure
- [ ] If tests passing: files_modified and git_commits present
- [ ] If tests failing: failed_phase and error_message present
- [ ] Status stored for use in Step 5 conditional branching

**Error Handling**:
If status extraction fails (cannot determine test status):
- Log warning: "Could not parse implementation status from agent output"
- Default to: tests_passing = false (safe default, triggers debugging)
- Continue to Step 5 with failure status

#### Step 5: Evaluate Test Status and Determine Next Phase

**EXECUTE NOW: Branch Workflow Based on Test Results**

EVALUATE the test status extracted in Step 4 and ROUTE the workflow accordingly.

**Branching Decision Tree**:

```
READ workflow_state.implementation_status.tests_passing

IF tests_passing == true:
    ├─→ ROUTE: Documentation Phase (Phase 6)
    ├─→ CHECKPOINT: implementation_complete
    ├─→ STATUS: Implementation successful, all tests passing
    └─→ PROCEED to Step 6 (Save Success Checkpoint)

ELSE (tests_passing == false):
    ├─→ ROUTE: Debugging Loop (Phase 5)
    ├─→ CHECKPOINT: implementation_incomplete
    ├─→ STATUS: Implementation failed, debugging required
    ├─→ PREPARE: Debug context with error details
    └─→ PROCEED to Step 6 (Save Failure Checkpoint)
```

**Decision Implementation**:

```python
# Execute this branching logic

if workflow_state.implementation_status.tests_passing == True:
    # SUCCESS PATH
    next_phase = "documentation"
    checkpoint_type = "implementation_complete"
    workflow_status = "Tests passing, implementation successful"

    # Prepare documentation context
    documentation_context = {
        "plan_path": workflow_state.implementation_context.plan_path,
        "files_modified": workflow_state.implementation_status.files_modified,
        "git_commits": workflow_state.implementation_status.git_commits,
        "test_status": "all passing"
    }

else:
    # FAILURE PATH
    next_phase = "debugging"
    checkpoint_type = "implementation_incomplete"
    workflow_status = "Tests failing, debugging required"

    # Prepare debugging context
    debug_context = {
        "plan_path": workflow_state.implementation_context.plan_path,
        "failed_phase": workflow_state.implementation_failure.failed_phase,
        "error_message": workflow_state.implementation_failure.error_message,
        "files_modified": workflow_state.implementation_status.files_modified,
        "phases_completed": workflow_state.implementation_status.phases_completed
    }
```

**Context Preparation**:

**FOR SUCCESS PATH** (tests passing):
```yaml
workflow_state.next_phase: "documentation"
workflow_state.documentation_context:
  plan_path: "[path]"
  implementation_complete: true
  files_modified: [array]
  git_commits: [array]
  test_results: "all passing"
```

**FOR FAILURE PATH** (tests failing):
```yaml
workflow_state.next_phase: "debugging"
workflow_state.debug_context:
  plan_path: "[path]"
  failed_phase: [N]
  error_message: "[details]"
  files_modified: [array]
  phases_completed: "[M]/[N]"
  iteration: 0
```

**Store Branch Decision**:
```yaml
workflow_state.implementation_branch:
  decision: "success|failure"
  next_phase: "documentation|debugging"
  timestamp: "[ISO 8601 timestamp]"
  reason: "[Test status explanation]"
```

**Verification Checklist**:
- [ ] Test status evaluated (not skipped)
- [ ] Branch decision made (success or failure path chosen)
- [ ] Context prepared for next phase
- [ ] Workflow state updated with next_phase
- [ ] If failure: debug_context includes all error details

#### Step 6: Save Checkpoint for Implementation Phase

**EXECUTE NOW: Save Checkpoint Based on Branch Decision**

SAVE checkpoint using checkpoint-utils.sh based on the branch decision from Step 5.

**Checkpoint Creation**:

**IF SUCCESS PATH** (tests passing):

```bash
# Create success checkpoint
CHECKPOINT_DATA=$(cat <<EOF
{
  "workflow": "orchestrate",
  "phase_name": "implementation",
  "completion_time": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "outputs": {
    "tests_passing": true,
    "phases_completed": "${PHASES_COMPLETED}",
    "files_modified": [${FILES_MODIFIED}],
    "git_commits": [${GIT_COMMITS}],
    "status": "success"
  },
  "next_phase": "documentation",
  "branch_decision": "success",
  "performance": {
    "implementation_time": "${DURATION_SECONDS}s",
    "phases_executed": ${PHASE_COUNT}
  },
  "context_for_next_phase": {
    "plan_path": "${PLAN_PATH}",
    "files_modified": [${FILES_MODIFIED}],
    "git_commits": [${GIT_COMMITS}]
  }
}
EOF
)

# Save checkpoint
.claude/lib/save-checkpoint.sh orchestrate "implementation_complete" "$CHECKPOINT_DATA"
```

**IF FAILURE PATH** (tests failing):

```bash
# Create failure checkpoint
CHECKPOINT_DATA=$(cat <<EOF
{
  "workflow": "orchestrate",
  "phase_name": "implementation",
  "completion_time": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "outputs": {
    "tests_passing": false,
    "phases_completed": "${PHASES_COMPLETED}",
    "failed_phase": ${FAILED_PHASE},
    "error_message": "${ERROR_MESSAGE}",
    "files_modified": [${FILES_MODIFIED}],
    "status": "failed"
  },
  "next_phase": "debugging",
  "branch_decision": "failure",
  "debug_context": {
    "plan_path": "${PLAN_PATH}",
    "failed_phase": ${FAILED_PHASE},
    "error_message": "${ERROR_MESSAGE}",
    "files_modified": [${FILES_MODIFIED}],
    "phases_completed": "${PHASES_COMPLETED}",
    "iteration": 0
  }
}
EOF
)

# Save checkpoint
.claude/lib/save-checkpoint.sh orchestrate "implementation_incomplete" "$CHECKPOINT_DATA"
```

**Checkpoint File Locations**:
- Success: `.claude/data/checkpoints/orchestrate_implementation_complete_[timestamp].json`
- Failure: `.claude/data/checkpoints/orchestrate_implementation_incomplete_[timestamp].json`

**Verification Checklist**:
- [ ] Checkpoint file created in .claude/data/checkpoints/
- [ ] Checkpoint contains all required fields (outputs, next_phase, context)
- [ ] If success: includes files_modified and git_commits
- [ ] If failure: includes failed_phase and error_message
- [ ] Checkpoint enables workflow resumption from this point

#### Step 7: Output Implementation Phase Status

**EXECUTE NOW: Display Status Message to User**

DISPLAY appropriate completion message based on branch decision from Step 5.

**IF SUCCESS PATH** (tests passing):

```markdown
OUTPUT to user:

✓ Implementation Phase Complete

**Summary**:
- All phases executed: [N]/[N]
- Tests passing: ✓
- Files modified: [M] files
- Git commits: [N] commits

**Modified Files**:
[List each file from workflow_state.implementation_status.files_modified]

**Git Commits**:
[List each commit hash from workflow_state.implementation_status.git_commits]

**Next Phase**: Documentation (Phase 6)

The implementation succeeded. Proceeding to documentation phase to update
project documentation and generate workflow summary.
```

**State Management** (Success Path):

UPDATE workflow_state after implementation phase completes successfully:

```yaml
workflow_state.current_phase = "documentation"
workflow_state.execution_tracking.phase_start_times["implementation"] = [impl start timestamp]
workflow_state.execution_tracking.phase_end_times["implementation"] = [current timestamp]
workflow_state.execution_tracking.agents_invoked += 1  # code-writer agent
workflow_state.completed_phases.append("implementation")
workflow_state.context_preservation.implementation_status.tests_passing = true
workflow_state.context_preservation.implementation_status.files_modified = [modified files array]
```

UPDATE TodoWrite to mark implementation complete and skip debugging (tests passed):

```json
{
  "todos": [
    // ... previous todos all marked completed ...
    {
      "content": "Implement features with testing",
      "status": "completed",
      "activeForm": "Implementing features with testing"
    },
    {
      "content": "Debug and fix test failures (if needed)",
      "status": "completed",
      "activeForm": "Debugging and fixing test failures (skipped - tests passed)"
    },
    {
      "content": "Generate documentation and workflow summary",
      "status": "in_progress",
      "activeForm": "Generating documentation and workflow summary"
    }
  ]
}
```

**IF FAILURE PATH** (tests failing):

```markdown
OUTPUT to user:

⚠ Implementation Phase Incomplete

**Summary**:
- Phases completed: [M]/[N]
- Failed at: Phase [N]
- Tests passing: ✗

**Failure Details**:
Phase [N] failed with error:
[error_message from workflow_state.implementation_failure.error_message]

**Partial Progress**:
Files modified before failure:
[List each file from workflow_state.implementation_status.files_modified]

**Next Phase**: Debugging Loop (Phase 5)

The implementation encountered test failures. Entering debugging loop to
investigate and fix issues. Maximum 3 debugging iterations before escalation.
```

**State Management** (Failure Path):

UPDATE workflow_state after implementation phase fails:

```yaml
workflow_state.current_phase = "debugging"
workflow_state.execution_tracking.phase_start_times["implementation"] = [impl start timestamp]
workflow_state.execution_tracking.phase_end_times["implementation"] = [current timestamp]
workflow_state.execution_tracking.agents_invoked += 1  # code-writer agent
workflow_state.completed_phases.append("implementation")  # Marked complete even if failed
workflow_state.context_preservation.implementation_status.tests_passing = false
workflow_state.context_preservation.implementation_status.files_modified = [partial files array]
workflow_state.execution_tracking.debug_iteration = 0  # Reset for debugging loop
```

UPDATE TodoWrite to mark implementation complete (with failure) and debugging as next:

```json
{
  "todos": [
    // ... previous todos all marked completed ...
    {
      "content": "Implement features with testing",
      "status": "completed",
      "activeForm": "Implementing features with testing (tests failed)"
    },
    {
      "content": "Debug and fix test failures (if needed)",
      "status": "in_progress",
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

**Implementation Instructions**:

```python
# Display message based on branch decision

if workflow_state.implementation_branch.decision == "success":
    print(f"""
✓ Implementation Phase Complete

**Summary**:
- All phases executed: {workflow_state.implementation_status.phases_completed}
- Tests passing: ✓
- Files modified: {len(workflow_state.implementation_status.files_modified)} files
- Git commits: {len(workflow_state.implementation_status.git_commits)} commits

**Modified Files**:
{format_file_list(workflow_state.implementation_status.files_modified)}

**Git Commits**:
{format_commit_list(workflow_state.implementation_status.git_commits)}

**Next Phase**: Documentation (Phase 6)
    """)

else:  # failure path
    print(f"""
⚠ Implementation Phase Incomplete

**Summary**:
- Phases completed: {workflow_state.implementation_status.phases_completed}
- Failed at: Phase {workflow_state.implementation_failure.failed_phase}
- Tests passing: ✗

**Failure Details**:
Phase {workflow_state.implementation_failure.failed_phase} failed with error:
{workflow_state.implementation_failure.error_message}

**Partial Progress**:
Files modified before failure:
{format_file_list(workflow_state.implementation_status.files_modified)}

**Next Phase**: Debugging Loop (Phase 5)
    """)
```

**Verification Checklist**:
- [ ] Appropriate message displayed (success or failure)
- [ ] Message includes all relevant details (files, commits, errors)
- [ ] Next phase clearly indicated
- [ ] User understands what happened and what comes next

### Debugging Loop (Conditional - Only if Tests Fail)

**ENTRY CONDITIONS**:
```yaml
if workflow_state.implementation_status.tests_passing == false:
  ENTER debugging loop
else:
  SKIP to Phase 6 (Documentation)
```

**EXECUTE NOW: Initialize Debugging State**

Before first iteration, initialize debugging state:

```yaml
workflow_state.debug_iteration = 0
workflow_state.debug_topic_slug = ""      # Generated in Step 1
workflow_state.debug_reports = []         # Populated each iteration
workflow_state.debug_history = []         # Tracks all attempts
```

**Iteration Limit**: Maximum 3 debugging iterations. After 3 failures, escalate to user with actionable options.

**Loop Strategy**: Each iteration follows this sequence:
1. Generate debug topic slug (iteration 1 only)
2. Invoke debug-specialist → create report file
3. Extract report path and recommendations
4. Invoke code-writer → apply fix from report
5. Run tests again
6. Evaluate results → continue, succeed, or escalate

---

#### Step 1: Generate Debug Topic Slug (First Iteration Only)

**EXECUTE NOW: Generate Topic Slug**

IF debug_iteration == 1 AND debug_topic_slug is empty:

ANALYZE the test failure error messages to categorize the issue type.

**Topic Slug Algorithm**:

1. **Phase-Based** (default): Use failed phase number from implementation
   - Format: `phase{N}_failures`
   - Example: Phase 1 failed → `phase1_failures`

2. **Error-Type-Based** (preferred if pattern clear):
   - Integration failures → `integration_issues`
   - Timeout errors → `test_timeout`
   - Configuration errors → `config_errors`
   - Missing dependencies → `dependency_missing`
   - Syntax/compilation → `syntax_errors`

3. **Slug Rules**:
   - Lowercase with underscores
   - Concise (2-3 words max)
   - Descriptive of root issue type

**EXECUTE: Create Slug**

```bash
# Example slug generation logic
if error_message contains "timeout":
  debug_topic_slug = "test_timeout"
elif error_message contains "config":
  debug_topic_slug = "config_errors"
elif error_message contains "integration":
  debug_topic_slug = "integration_issues"
elif error_message contains "dependency" or "module not found":
  debug_topic_slug = "dependency_missing"
else:
  # Default: use failed phase number
  debug_topic_slug = "phase{failed_phase_number}_failures"
```

**Store in workflow_state**:
```yaml
workflow_state.debug_topic_slug = "[generated_slug]"
```

**Examples**:
- Integration test failure → `integration_issues`
- Phase 1 config loading error → `phase1_failures` or `config_errors`
- Test timeout in Phase 3 → `test_timeout`

---

#### Step 2: Invoke Debug Specialist Agent with File Creation

**EXECUTE NOW: USE the Task tool to invoke debug-specialist agent**

This agent will:
- Investigate test failure root cause
- Analyze error messages and code context
- Create persistent debug report file
- Propose 2-3 solution options
- Recommend best fix approach

**Task Tool Invocation** (execute this now):

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Create debug report for test failures using debug-specialist protocol"
  prompt: |
    Read and follow the behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/debug-specialist.md

    You are acting as a Debug Specialist Agent with the tools and constraints
    defined in that file.

    Create Debug Report File for Implementation Test Failures:

    ## Context
    - **Workflow**: "[workflow_state.workflow_description]"
    - **Project**: [project_name]
    - **Failed Phase**: Phase [failed_phase_number] - [phase_name]
    - **Topic Slug**: [workflow_state.debug_topic_slug]
    - **Iteration**: [workflow_state.debug_iteration] of 3

    ## Test Failures
    [workflow_state.implementation_status.test_output]

    ## Error Details
    - **Error messages**:
      [workflow_state.implementation_status.error_messages]

    - **Modified files**:
      [workflow_state.implementation_status.files_modified]

    - **Plan reference**: [workflow_state.plan_path]

    [IF debug_iteration > 1:]
    ## Previous Debug Attempts
    [FOR each attempt in workflow_state.debug_history:]
    ### Iteration [attempt.iteration]
    - **Report**: [attempt.report_path]
    - **Fix attempted**: [attempt.fix_attempted]
    - **Result**: [attempt.result]
    - **New errors**: [attempt.new_errors]

    ## Investigation Requirements
    - Analyze test failure patterns and root cause
    - Review relevant code and configurations
    - Consider previous debug attempts (if iteration > 1)
    - Identify why previous fixes didn't work (if applicable)
    - Propose 2-3 solutions with tradeoffs
    - Recommend the most likely solution to succeed

    ## Debug Report Creation Instructions
    1. USE Glob to find existing reports: `debug/[debug_topic_slug]/[0-9][0-9][0-9]_*.md`
    2. DETERMINE next report number (NNN format, incremental)
    3. CREATE report file using Write tool:
       Path: `debug/[debug_topic_slug]/NNN_[descriptive_name].md`
    4. INCLUDE all required metadata fields (see agent file, lines 256-346)
    5. RETURN file path in parseable format

    ## Expected Output Format

    **Primary Output** (required):
    ```
    DEBUG_REPORT_PATH: debug/[topic]/NNN_descriptive_name.md
    ```

    **Secondary Output** (required):
    Brief summary (1-2 sentences):
    - Root cause: [What is causing the failure]
    - Recommended fix: Option [N] - [Brief description]

    Example:
    ```
    DEBUG_REPORT_PATH: debug/phase1_failures/001_config_initialization.md

    Root cause: Config file not initialized before first test runs.
    Recommended fix: Option 2 - Add config initialization in test setup hook
    ```
}
```

**WAIT for agent completion before proceeding.**

---

#### Step 3: Extract Debug Report Path and Recommendations

**EXECUTE NOW: Parse Debug Specialist Output**

From the debug-specialist agent output, EXTRACT the following information:

**Required Extraction**:

1. **Debug Report Path**:
   - Pattern: `DEBUG_REPORT_PATH: debug/{topic}/NNN_*.md`
   - Example: `DEBUG_REPORT_PATH: debug/phase1_failures/001_config_initialization.md`
   - Store in: `debug_report_path` variable

2. **Root Cause Summary**:
   - Pattern: After "Root cause:" line
   - Extract: Brief 1-2 sentence description
   - Store in: `root_cause` variable

3. **Recommended Fix**:
   - Pattern: After "Recommended fix:" line
   - Extract: Which option number and brief description
   - Store in: `recommended_fix` variable

**EXECUTE: Validation Checklist**

Before proceeding, verify:
- [ ] Debug report file exists at extracted path
- [ ] File contains all required metadata sections
- [ ] Root cause clearly identified
- [ ] 2-3 solution options proposed with tradeoffs
- [ ] Recommended solution explicitly specified
- [ ] File follows debug report structure (see debug-specialist.md lines 256-346)

**IF validation fails**:
- RETRY debug-specialist invocation with clarifying instructions
- Maximum 2 retries before escalating to user

**EXECUTE: Store in Workflow State**

```yaml
workflow_state.debug_reports.append(debug_report_path)

# Example state after extraction:
workflow_state:
  debug_reports: [
    "debug/phase1_failures/001_config_initialization.md"
  ]
```

**Example Parsed Output**:
```
debug_report_path = "debug/phase1_failures/001_config_initialization.md"
root_cause = "Config file not initialized before first test runs"
recommended_fix = "Option 2 - Add config initialization in test setup hook"
```

---

#### Step 4: Apply Recommended Fix Using Code Writer Agent

**EXECUTE NOW: USE the Task tool to invoke code-writer agent**

This agent will:
- Read the debug report created in Step 3
- Understand the root cause and proposed solutions
- Implement the recommended solution
- Apply changes to affected files
- Prepare code for testing (but NOT run tests yet)

**Task Tool Invocation** (execute this now):

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Apply debug fixes from report using code-writer protocol"
  prompt: |
    Read and follow the behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/code-writer.md

    You are acting as a Code Writer Agent with the tools and constraints
    defined in that file.

    Apply fixes from debug report:

    ## Debug Report
    **Path**: [debug_report_path from Step 3]

    READ the report using the Read tool to understand:
    - Root cause of test failures (Analysis section)
    - Proposed solutions (Options 1-3 in Proposed Solutions section)
    - Recommended solution (Recommendation section)
    - Implementation steps (within recommended solution option)

    ## Task
    IMPLEMENT the recommended solution from the debug report.

    ## Requirements
    - Follow implementation steps from recommended solution option
    - Apply changes to affected files using Edit or Write tools
    - Follow project coding standards (reference: /home/benjamin/.config/CLAUDE.md)
    - Add comments explaining the fix where appropriate
    - DO NOT run tests yet (orchestrator will run tests in Step 5)

    ## Context for Implementation
    - **Iteration**: [workflow_state.debug_iteration] of 3
    - **Previous attempts**: [IF iteration > 1: summary of previous fixes]
    - **Files to modify**: [From debug report's recommended solution]

    ## Expected Output
    Provide a brief summary:
    - **Files modified**: [list of files changed]
    - **Changes made**: [brief description of what was fixed]
    - **Ready for testing**: true

    Example:
    ```
    Files modified:
    - tests/setup.lua
    - config/init.lua

    Changes made:
    - Added config initialization in test setup hook
    - Ensured config loads before first test runs

    Ready for testing: true
    ```
}
```

**WAIT for agent completion before proceeding to testing.**

**EXECUTE: Capture Fix Summary**

From code-writer output, extract:
- `files_modified`: List of files changed
- `fix_description`: Brief summary of changes
- Store for debug history in Step 7

---

#### Step 5: Run Tests Again

**EXECUTE NOW: Run Tests to Validate Fix**

After code-writer applies the fix, run tests to determine if issue is resolved.

**Test Command Determination**:

1. **From Plan** (preferred): Check `workflow_state.plan_path` for test command
2. **From CLAUDE.md** (fallback): Check Testing Protocols section
3. **Default**: Use project-standard test command

**EXECUTE: Run Test Command**

```bash
# Execute test command via Bash tool
# Example commands (use appropriate for project):

# Claude Code project:
bash .claude/tests/run_all_tests.sh

# Python project:
pytest tests/

# JavaScript project:
npm test

# General:
[test_command from plan or CLAUDE.md]
```

**EXECUTE: Capture Test Results**

Parse test output to extract:

1. **Test Status**:
   ```yaml
   tests_passing: true | false
   ```

2. **Test Output** (if failing):
   ```yaml
   test_output: "[Full test output for next iteration context]"
   error_messages: [
     "Error 1 from output",
     "Error 2 from output"
   ]
   ```

3. **Success Indicators**:
   - All tests pass: `tests_passing = true`
   - Same errors: `tests_passing = false, errors unchanged`
   - New errors: `tests_passing = false, errors different`
   - Fewer errors: `tests_passing = false, progress = true`

**EXECUTE: Update Workflow State**

```yaml
workflow_state.implementation_status.tests_passing = [true|false]
workflow_state.implementation_status.test_output = "[latest output]"
workflow_state.implementation_status.error_messages = [extracted errors]
```

**Example Result**:
```yaml
# Success case:
tests_passing: true
test_output: "All 47 tests passed in 12.3s"

# Failure case:
tests_passing: false
test_output: "[Full output showing 3 failing tests]"
error_messages: [
  "test_auth: JWT decode error",
  "test_session: Token validation failed",
  "test_middleware: nil config.secret"
]
```

---

#### Step 6: Iteration Control and Decision Logic

**EXECUTE NOW: Evaluate Test Results and Determine Next Action**

Based on test results from Step 5, execute the appropriate branch:

```python
# Increment iteration counter (always at loop start)
# NOTE: Counter incremented at START of iteration, not end
workflow_state.debug_iteration += 1

# Decision tree (evaluate in this order):

IF tests_passing == true:
  # SUCCESS PATH
  EXECUTE: Branch 1 - Tests Passing (Success)

ELIF debug_iteration >= 3:
  # ESCALATION PATH (limit reached)
  EXECUTE: Branch 2 - Escalation to User

ELSE:
  # CONTINUE PATH (try again)
  EXECUTE: Branch 3 - Continue Debugging Loop
```

---

### Branch 1: Tests Passing (Success)

**Condition**: `tests_passing == true`

**EXECUTE: Success Actions**

1. **Mark debugging successful**:
   ```yaml
   workflow_state.debug_status = "resolved"
   workflow_state.debug_iterations_needed = debug_iteration
   ```

2. **Add resolution to debug history**:
   ```yaml
   workflow_state.debug_history.append({
     iteration: debug_iteration,
     report_path: debug_report_path,
     fix_attempted: fix_description,
     result: "Tests passing",
     resolution: "Success"
   })
   ```

3. **Update error history** (for tracking):
   ```yaml
   workflow_state.error_history.append({
     phase: "implementation",
     issue: root_cause,
     debug_reports: workflow_state.debug_reports,
     resolution: "Fixed in iteration {debug_iteration}",
     fix_applied: fix_description
   })
   ```

4. **SAVE checkpoint**:
   ```bash
   # Create checkpoint file with success status
   cat > .claude/checkpoints/checkpoint_tests_passing.yaml << 'EOF'
   phase_name: "debugging"
   completion_time: $(date -Iseconds)
   outputs:
     tests_passing: true
     debug_iterations: ${debug_iteration}
     debug_reports: ${workflow_state.debug_reports[@]}
     issues_resolved: ["${root_cause}"]
     status: "success"
   next_phase: "documentation"
   performance:
     debugging_time: "${duration}"
     iterations_needed: ${debug_iteration}
   EOF
   ```

5. **OUTPUT to user**:
   ```markdown
   ✓ Debugging Phase Complete

   Tests passing: ✓
   Debug iterations: {debug_iteration}
   Issues resolved: {issues_count}
   Debug reports: {report_paths}

   Next: Documentation Phase
   ```

**State Management** (Debugging Success):

UPDATE workflow_state after debugging completes successfully:

```yaml
workflow_state.current_phase = "documentation"
workflow_state.execution_tracking.phase_start_times["debugging"] = [debug start timestamp]
workflow_state.execution_tracking.phase_end_times["debugging"] = [current timestamp]
workflow_state.execution_tracking.debug_iteration = [final iteration number]
workflow_state.execution_tracking.agents_invoked += [debug_iteration × 2]  # debug-specialist + code-writer per iteration
workflow_state.completed_phases.append("debugging")
workflow_state.context_preservation.debug_reports = [array of debug report paths]
workflow_state.context_preservation.implementation_status.tests_passing = true
```

UPDATE TodoWrite to mark debugging complete:

```json
{
  "todos": [
    // ... previous todos all marked completed ...
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
      "status": "in_progress",
      "activeForm": "Generating documentation and workflow summary"
    }
  ]
}
```

**EXIT debugging loop → PROCEED to Phase 6 (Documentation)**

---

### Branch 2: Escalation to User

**Condition**: `debug_iteration >= 3 AND tests_passing == false`

**EXECUTE: Escalation Actions**

1. **Mark debugging as escalated**:
   ```yaml
   workflow_state.debug_status = "escalated"
   workflow_state.debug_iterations_needed = 3
   ```

2. **Add final attempt to debug history**:
   ```yaml
   workflow_state.debug_history.append({
     iteration: 3,
     report_path: debug_report_path,
     fix_attempted: fix_description,
     result: "Still failing after 3 iterations",
     escalation_reason: "Maximum debugging iterations reached"
   })
   ```

3. **SAVE escalation checkpoint**:
   ```bash
   # Create escalation checkpoint
   cat > .claude/checkpoints/checkpoint_escalation.yaml << 'EOF'
   phase_name: "debugging"
   completion_time: $(date -Iseconds)
   outputs:
     tests_passing: false
     debug_iterations: 3
     debug_reports: ${workflow_state.debug_reports[@]}
     unresolved_issues: ${workflow_state.implementation_status.error_messages[@]}
     status: "escalated"
   next_phase: "manual_intervention"
   user_options: ["continue", "retry", "rollback", "terminate"]
   debug_summary: |
     Attempted 3 debugging iterations. Tests still failing.

     Issues remaining:
     ${workflow_state.implementation_status.error_messages[@]}

     Debug reports created:
     ${workflow_state.debug_reports[@]}
   EOF
   ```

4. **PRESENT escalation message to user**:

```markdown
⚠️ **Debugging Loop: Maximum Iterations Reached**

**Status**: Escalation required after 3 debugging iterations

---

## Issue Summary

**Original Problem**:
[Root cause from first debug report: workflow_state.debug_history[0].root_cause]

**Tests Status**: Still failing after 3 fix attempts

**Unresolved Errors**:
[FOR each error in workflow_state.implementation_status.error_messages:]
- {error}

---

## Debugging Attempts

### Iteration 1
- **Debug Report**: {workflow_state.debug_reports[0]}
- **Fix Attempted**: {workflow_state.debug_history[0].fix_attempted}
- **Result**: {workflow_state.debug_history[0].result}
- **New Errors**: {workflow_state.debug_history[0].new_errors}

### Iteration 2
- **Debug Report**: {workflow_state.debug_reports[1]}
- **Fix Attempted**: {workflow_state.debug_history[1].fix_attempted}
- **Result**: {workflow_state.debug_history[1].result}
- **New Errors**: {workflow_state.debug_history[1].new_errors}

### Iteration 3
- **Debug Report**: {workflow_state.debug_reports[2]}
- **Fix Attempted**: {workflow_state.debug_history[2].fix_attempted}
- **Result**: {workflow_state.debug_history[2].result}
- **New Errors**: {workflow_state.debug_history[2].new_errors}

---

## Your Options

I've reached the maximum automated debugging iterations (3). Here are your options:

**Option 1: Manual Investigation**
- Review the 3 debug reports created:
  - {workflow_state.debug_reports[0]}
  - {workflow_state.debug_reports[1]}
  - {workflow_state.debug_reports[2]}
- Manually investigate and fix the issue
- Resume workflow after fixing: Use checkpoint_escalation to resume

**Option 2: Retry with Guidance**
- Provide additional context or hints about the issue
- I'll retry debugging with your guidance
- Command: `/orchestrate resume --with-context "your guidance"`

**Option 3: Alternative Approach**
- Rollback to last successful phase (Phase 4: Implementation complete)
- Try a different implementation approach
- Command: `/orchestrate rollback phase4`

**Option 4: Skip Debugging**
- Proceed to documentation phase despite failing tests
- Mark tests as "known issues" in documentation
- Command: `/orchestrate continue --skip-tests`

**Option 5: Terminate Workflow**
- End workflow here, preserve all work completed
- Checkpoints saved: research, planning, implementation, debugging attempts
- Command: `/orchestrate terminate`

---

## Checkpoint Saved

A checkpoint has been saved at:
- **Checkpoint ID**: `checkpoint_escalation`
- **Phase**: debugging (incomplete)
- **Resume Command**: `/orchestrate resume`

All debug reports, implementation work, and history are preserved.

---

## Recommended Next Steps

1. **Investigate manually**: Start with the most recent debug report ({workflow_state.debug_reports[2]})
2. **Check for patterns**: Do all 3 attempts share a common issue?
3. **Review test configuration**: Are tests themselves correct?
4. **Consider scope**: Is this issue within original workflow scope?

**What would you like to do?** [Respond with option number or custom action]
```

**PAUSE workflow and WAIT for user input.**

**EXIT debugging loop → Wait for user decision**

---

### Branch 3: Continue Debugging Loop

**Condition**: `debug_iteration < 3 AND tests_passing == false`

**EXECUTE: Prepare for Next Iteration**

1. **Add current attempt to debug history**:
   ```yaml
   workflow_state.debug_history.append({
     iteration: debug_iteration,
     report_path: debug_report_path,
     fix_attempted: fix_description,
     result: "Still failing",
     new_errors: workflow_state.implementation_status.error_messages
   })
   ```

2. **Prepare context for next iteration**:
   - Keep `workflow_state.debug_topic_slug` (don't regenerate)
   - Keep `workflow_state.debug_reports` (accumulate)
   - Keep `workflow_state.debug_history` (accumulate)
   - Update `error_messages` with latest failures

3. **OUTPUT to user**:
   ```markdown
   Debugging iteration {debug_iteration} complete.
   Tests still failing. Attempting iteration {debug_iteration + 1}...
   ```

4. **RETURN to Step 2** (Invoke Debug Specialist) with enriched context:
   - Next invocation will include debug_history
   - debug-specialist will see previous attempts
   - code-writer will know what was already tried

**CONTINUE debugging loop → RETURN to Step 2 (iteration {debug_iteration + 1})**

---

**Summary of Decision Logic**:

| Condition | Action | Next Phase |
|-----------|--------|------------|
| Tests passing | Save success checkpoint | Phase 6 (Documentation) |
| Iteration >= 3, tests failing | Save escalation checkpoint, present options | User Decision |
| Iteration < 3, tests failing | Add to history, continue loop | Step 2 (next iteration) |

---

#### Step 7: Update Workflow State (All Branches)

**EXECUTE: Update workflow_state (performed in all branches)**

Update workflow state based on debugging outcome:

```yaml
# State updated in Branch 1 (Success):
workflow_state.context_preservation.debug_reports: [
  {
    topic: "[debug_topic_slug]",
    path: "debug/{topic}/NNN_*.md",
    number: "NNN",
    iteration: N,
    resolved: true
  }
]

# State updated in Branch 2 (Escalation):
workflow_state.context_preservation.debug_reports: [
  {topic: "...", path: "...", resolved: false},
  {topic: "...", path: "...", resolved: false},
  {topic: "...", path: "...", resolved: false}
]

# State updated in Branch 3 (Continue):
workflow_state.debug_history: [
  {iteration: 1, result: "Still failing", ...},
  {iteration: 2, result: "Still failing", ...}
]
```

---

#### Debugging Loop Code Examples

**Example 1: Single Iteration Success**

```yaml
# Scenario: Fix works on first try

Iteration 1:
  debug_iteration: 1
  debug_topic_slug: "phase1_failures"

  Step 2: debug-specialist creates:
    - Report: debug/phase1_failures/001_config_initialization.md
    - Root cause: "Config not initialized before tests"
    - Recommended: "Option 2 - Add init in test setup"

  Step 3: Extract:
    - debug_report_path = "debug/phase1_failures/001_config_initialization.md"

  Step 4: code-writer applies:
    - Modified: tests/setup.lua
    - Added: config.init() call in setup function

  Step 5: Run tests:
    - Result: All 47 tests pass
    - tests_passing = true

  Step 6: Branch 1 (Success):
    - Save checkpoint(success)
    - debug_iterations_needed = 1
    - EXIT loop → Phase 6 (Documentation)

Outcome: ✓ Success in 1 iteration
```

**Example 2: Two Iteration Success**

```yaml
# Scenario: First fix incomplete, second fix succeeds

Iteration 1:
  debug_iteration: 1
  debug_topic_slug: "integration_issues"

  Step 2: debug-specialist creates:
    - Report: debug/integration_issues/001_auth_token_missing.md
    - Root cause: "Auth token not passed to middleware"
    - Recommended: "Option 1 - Add token to request context"

  Step 4: code-writer applies:
    - Modified: middleware/auth.lua
    - Added: token extraction from headers

  Step 5: Run tests:
    - Result: 2 tests still failing
    - Error: "config.secret is nil"
    - tests_passing = false

  Step 6: Branch 3 (Continue):
    - Add to debug_history[0]
    - CONTINUE to Iteration 2

Iteration 2:
  debug_iteration: 2
  debug_topic_slug: "integration_issues" (reuse)

  Step 2: debug-specialist creates (with history):
    - Report: debug/integration_issues/002_secret_initialization.md
    - Context: "Previous fix addressed token extraction, but config.secret still nil"
    - Root cause: "Secret not loaded in test environment"
    - Recommended: "Option 2 - Mock secret in test config"

  Step 4: code-writer applies:
    - Modified: tests/config_mock.lua
    - Added: config.secret = "test-secret-key"

  Step 5: Run tests:
    - Result: All tests pass
    - tests_passing = true

  Step 6: Branch 1 (Success):
    - Save checkpoint(success)
    - debug_iterations_needed = 2
    - EXIT loop → Phase 6 (Documentation)

Outcome: ✓ Success in 2 iterations
```

**Example 3: Three Iteration Escalation**

```yaml
# Scenario: Issue proves too complex for automated debugging

Iteration 1:
  debug_topic_slug: "test_timeout"
  Report: debug/test_timeout/001_async_hang.md
  Fix: Added timeout wrapper
  Result: Still hangs (different line)

Iteration 2:
  Report: debug/test_timeout/002_promise_deadlock.md
  Fix: Fixed promise resolution order
  Result: New error - "coroutine error"

Iteration 3:
  debug_iteration: 3
  Report: debug/test_timeout/003_coroutine_state.md
  Fix: Added coroutine state cleanup
  Result: Still failing - "coroutine in wrong state"
  tests_passing = false

Step 6: Branch 2 (Escalation):
  debug_iteration >= 3 AND tests_passing == false
  SAVE checkpoint(escalation)
  PRESENT escalation message with 3 reports
  PAUSE workflow
  WAIT for user decision

Outcome: ⚠️ Escalated to user after 3 iterations
```

### Documentation Phase (Sequential Execution)

This phase completes the workflow by updating project documentation, generating a comprehensive workflow summary with performance metrics, establishing bidirectional cross-references between all artifacts, and optionally creating a pull request.

#### Step 1: Prepare Documentation Context

GATHER workflow artifacts and build documentation context structure for the doc-writer agent.

**EXECUTE NOW: Gather Workflow Artifacts**

EXTRACT the following from workflow_state and prior phase checkpoints:

1. **Research report paths** (from research phase checkpoint, if completed)
2. **Implementation plan path** (from planning phase checkpoint)
3. **Implementation status** (from implementation phase checkpoint)
4. **Debug report paths** (from debugging phase checkpoint, if occurred)
5. **Modified files list** (from implementation agent output)
6. **Test results** (passing or fixed_after_debugging)

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

  # From debugging phase (if occurred)
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

  ### Documentation Requirements

  1. **Update Project Documentation**:
     - Review files modified during implementation
     - Update relevant README files
     - Add usage examples where appropriate
     - Ensure documentation follows CLAUDE.md standards

  2. **Create Workflow Summary**:
     Create a comprehensive workflow summary file at:
     `[plan_directory]/specs/summaries/[plan_number]_workflow_summary.md`

     Use this exact template:

     ```markdown
     # Workflow Summary: [Feature/Task Name]

     ## Metadata
     - **Date Completed**: [YYYY-MM-DD]
     - **Specs Directory**: [specs_directory_path]
     - **Summary Number**: [NNN] (matches plan number)
     - **Workflow Type**: [feature|refactor|debug|investigation]
     - **Original Request**: [workflow_description]
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

#### Step 4: Extract Documentation Results

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
4. **Context overflow** (cannot compress further)
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
- Implement: code-writer executes plan (may fail tests initially)
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
- Seamless integration with /plan, /implement, /debug, /document commands
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

### Agent Integration Benefits
- **Specialized Expertise**: Each agent optimized for its specific task
- **Tool Restrictions**: Security through limited tool access per agent
- **Parallel Execution**: Research-specialist agents run concurrently
- **Context Isolation**: Agents receive only relevant context for their phase
- **Clear Responsibilities**: No ambiguity about which agent handles what

## Checkpoint Detection and Resume

Before starting the workflow, I'll check for existing checkpoints that might indicate an interrupted workflow.

### Step 1: Check for Existing Checkpoint

```bash
# Load most recent orchestrate checkpoint
CHECKPOINT=$(.claude/lib/load-checkpoint.sh orchestrate 2>/dev/null || echo "")
```

### Step 2: Interactive Resume Prompt (if checkpoint found)

If a checkpoint exists, I'll present interactive options:

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
