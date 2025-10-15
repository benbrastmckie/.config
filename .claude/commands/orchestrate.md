---
allowed-tools: Task, TodoWrite, Read, Write, Bash, Grep, Glob
argument-hint: <workflow-description> [--parallel] [--sequential] [--create-pr] [--dry-run]
description: Coordinate subagents through end-to-end development workflows
command-type: primary
dependent-commands: report, plan, implement, debug, test, document, github-specialist
---

# Multi-Agent Workflow Orchestration

I'll coordinate multiple specialized subagents through a complete development workflow, from research to documentation, while preserving context and enabling intelligent parallelization.

## Reference Files

This command uses standardized patterns defined in external reference files:

- **Agent Templates**: `.claude/templates/orchestration-patterns.md`
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

**See comprehensive patterns in**: `.claude/templates/orchestration-patterns.md#error-recovery-patterns`

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

See `.claude/templates/orchestration-patterns.md` for detailed implementation examples.

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

The /orchestrate command coordinates workflows through four main phases: Research (parallel), Planning (sequential), Implementation (adaptive), and Documentation (sequential). Each phase has specific execution patterns, checkpoint management, and error recovery procedures.

**See**: [Workflow Phases Documentation](shared/workflow-phases.md) for comprehensive details on:

- **Research Phase (Parallel Execution)**: Multi-agent parallel research with complexity scoring, thinking mode determination, report verification, and automatic path mismatch recovery
- **Planning Phase (Sequential Execution)**: Single-agent plan synthesis with context preparation, plan validation, and checkpoint management
- **Implementation Phase (Adaptive Execution)**: Plan execution with /implement command, conditional debugging loop (max 3 iterations), and escalation handling
- **Documentation Phase (Sequential Execution)**: Documentation updates, workflow summary generation, bidirectional cross-references, and optional PR creation

**Quick Phase Overview**:

1. **Research** → Identify 2-4 topics, launch agents in parallel, verify reports, save checkpoint
2. **Planning** → Prepare context, invoke plan-architect, validate plan, save checkpoint
3. **Implementation** → Execute plan, run tests, conditionally debug (max 3 iterations), save checkpoint
4. **Documentation** → Update docs, generate summary, create cross-references, optionally create PR

Each phase includes detailed execution procedures, agent invocation patterns, result parsing algorithms, checkpoint structures, and error recovery strategies.

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
