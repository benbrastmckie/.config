# /coordinate Implementation Approach Analysis

## Metadata
- **Date**: 2025-11-11
- **Agent**: research-specialist
- **Topic**: Current /coordinate implementation approach - specifically how it invokes /implement
- **Report Type**: Codebase analysis and architectural pattern comparison
- **Complexity Level**: 2

## Executive Summary

The /coordinate command currently violates the behavioral injection pattern (Standard 11) by invoking /implement as a slash command through the Task tool, rather than delegating to the implementer-coordinator agent directly. This creates command-to-command invocation issues including context bloat, loss of path control, and breaks wave-based parallel execution. Both /orchestrate and /supervise properly use the implementer-coordinator agent via behavioral injection. The fix requires replacing the SlashCommand invocation pattern with direct agent delegation.

## Findings

### 1. Current /coordinate Implementation (VIOLATES Standard 11)

**Location**: `/home/benjamin/.config/.claude/commands/coordinate.md:1089-1107`

**Current Pattern** (lines 1089-1107):
```markdown
**EXECUTE NOW**: USE the Task tool to invoke /implement command:

Task {
  subagent_type: "general-purpose"
  description: "Execute implementation plan with automated testing and commits"
  timeout: 600000
  prompt: "
    Execute the /implement slash command with the following arguments:

    /implement \"$PLAN_PATH\"

    This will execute the implementation plan phase-by-phase with:
    - Automated testing after each phase
    - Git commits for completed phases
    - Progress tracking and checkpoints

    Return: IMPLEMENTATION_COMPLETE: [summary or status]
  "
}
```

**Problems with This Approach**:

1. **Command-to-Command Invocation**: Invokes /implement as a slash command instead of using implementer-coordinator agent
2. **Context Bloat**: Nests full /implement command prompt (5,000+ lines) inside /coordinate prompt
3. **Loss of Path Control**: Cannot pre-calculate artifact paths or inject context
4. **Wave Execution Loss**: /implement is a sequential command, not wave-based parallel coordinator
5. **Metadata Extraction Failure**: Cannot extract metadata before full content loaded
6. **Recursion Risk**: Command → command invocation creates layering issues

### 2. Correct Implementation in /orchestrate

**Location**: `/home/benjamin/.config/.claude/commands/orchestrate.md:376-396`

**Correct Pattern** (lines 376-396):
```markdown
**EXECUTE NOW**: USE the Task tool to invoke implementer-coordinator:

Task {
  subagent_type: "general-purpose"
  description: "Execute implementation with wave-based parallel execution"
  timeout: 600000
  prompt: "
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/implementer-coordinator.md

    Plan File: $PLAN_PATH
    Workflow Options: $WORKFLOW_OPTIONS

    Execute implementation with:
    - Wave-based parallel execution for independent phases
    - Automated testing after each wave
    - Git commits for completed phases

    Return: IMPLEMENTATION_COMPLETE: [summary]
  "
}
```

**Why This Works**:

1. **Behavioral Injection**: References `.claude/agents/implementer-coordinator.md` behavioral file
2. **Context Injection**: Injects plan path and workflow options directly into agent prompt
3. **Wave-Based Execution**: implementer-coordinator orchestrates parallel phase execution
4. **Metadata Only**: Agent returns summary, not full content (95% context reduction)
5. **Path Control**: Orchestrator maintains control over artifact paths
6. **Clear Role Separation**: Agent is executor, command is orchestrator

### 3. Correct Implementation in /supervise

**Location**: `/home/benjamin/.config/.claude/commands/supervise.md:260-273`

**Correct Pattern** (lines 260-273):
```markdown
**EXECUTE NOW**: USE the Task tool for implementer-coordinator:

Task {
  subagent_type: "general-purpose"
  description: "Execute implementation"
  timeout: 600000
  prompt: "
    Read: ${CLAUDE_PROJECT_DIR}/.claude/agents/implementer-coordinator.md

    Plan: $PLAN_PATH

    Return: IMPLEMENTATION_COMPLETE
  "
}
```

**Key Differences from /coordinate**:

1. **Agent Reference**: References `implementer-coordinator.md`, not `/implement` command
2. **Minimal Context**: Only plan path injected, not full command invocation
3. **Direct Delegation**: No nested slash command execution
4. **State Machine Integration**: Works with state-based orchestration architecture

### 4. Standard 11: Imperative Agent Invocation Pattern

**Source**: `/home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md:1173-1352`

**Core Requirements** (lines 1175-1183):

Every agent invocation MUST include:
1. **Imperative Directive**: `**EXECUTE NOW**: USE the Task tool...`
2. **Behavioral Reference**: `Read and follow behavioral guidelines from: .claude/agents/{agent}.md`
3. **Context Injection**: Pre-calculated paths, constraints, specifications
4. **Completion Signal**: `Return: {SIGNAL}: {metadata}`

**Prohibited Patterns** (lines 1312-1332):

1. **Command-to-Command Invocation**: Using SlashCommand tool to invoke other commands
2. **Documentation-Only YAML**: YAML blocks without imperative directives
3. **Ambiguous Role**: No explicit "DO NOT execute yourself" instruction
4. **Direct Execution**: Command using Read/Grep/Write instead of delegating to agents

**Why Command-to-Command Fails** (from Standard 11, lines 312-332):

From command_architecture_standards.md:
```
**Problem**: Command-to-command invocation via SlashCommand
- Commands calling other commands (e.g., `/orchestrate` calling `/plan`, `/implement`)
- Loss of artifact path control (cannot pre-calculate topic-based paths)
- Context bloat (cannot extract metadata before full content loaded)
- Recursion risk (command → command → command loops)

**Solution**: Distinguish between orchestrator and executor roles:

**Orchestrator Role** (coordinates workflow):
- Pre-calculates all artifact paths (topic-based organization)
- Invokes specialized subagents via Task tool (NOT SlashCommand)
- Injects complete context into subagents (behavioral injection pattern)
- Verifies artifacts created at expected locations
- Extracts metadata only (95% context reduction)
- Examples: `/orchestrate`, `/plan` (when coordinating research agents)

**Executor Role** (performs atomic operations):
- Receives pre-calculated paths from orchestrator
- Executes specific task using Read/Write/Edit/Bash tools
- Creates artifacts at exact paths provided
- Returns metadata only (not full content)
- Examples: research-specialist agent, plan-architect agent, implementation-executor agent
```

### 5. The implementer-coordinator Agent

**Location**: `/home/benjamin/.config/.claude/agents/implementer-coordinator.md`

**Role** (lines 11-22):
- Wave-based implementation coordinator
- Orchestrates parallel phase execution using dependency analysis
- Invokes implementation-executor subagents for each phase
- Progress monitoring and state management
- Failure handling and result aggregation

**Key Capabilities**:
1. **Dependency Analysis**: Builds execution structure from plan dependencies
2. **Wave Orchestration**: Executes phases wave-by-wave with parallel executors
3. **Parallel Execution**: Multiple implementation-executor subagents run simultaneously
4. **Time Savings**: 40-60% reduction through parallelization
5. **State Management**: Maintains implementation state across waves

**Why /implement Command Cannot Replace This**:

The /implement command (`.claude/commands/implement.md`) is designed for:
- **Direct user invocation**: User runs `/implement plan.md` from CLI
- **Sequential execution**: Executes phases one by one
- **Interactive features**: Adaptive replanning, scope drift reporting, PR creation
- **User feedback**: Progress display, confirmation prompts

The implementer-coordinator agent is designed for:
- **Orchestrator invocation**: Called by /coordinate, /orchestrate, /supervise
- **Wave-based parallel execution**: Multiple phases run simultaneously
- **Non-interactive**: Returns metadata only, no user prompts
- **Metadata return**: Summary instead of full output

### 6. Behavioral Injection Pattern Documentation

**Source**: `/home/benjamin/.config/.claude/docs/concepts/patterns/behavioral-injection.md`

**Definition** (lines 9-16):
```
Behavioral Injection is a pattern where orchestrating commands inject execution context,
artifact paths, and role clarifications into agent prompts through file content rather
than tool invocations. This transforms agents from autonomous executors into orchestrated
workers that follow injected specifications.

The pattern separates:
- **Command role**: Orchestrator that calculates paths, manages state, delegates work
- **Agent role**: Executor that receives context via file reads and produces artifacts
```

**Problems Solved** (lines 21-37):

Commands that invoke other commands using the SlashCommand tool create two critical problems:

1. **Role Ambiguity**: When a command says "I'll research the topic", Claude interprets this as "I should execute research directly using Read/Grep/Write tools" instead of "I should orchestrate agents to research". This prevents hierarchical multi-agent patterns.

2. **Context Bloat**: Command-to-command invocations nest full command prompts within parent prompts, causing exponential context growth and breaking metadata-based context reduction.

Behavioral Injection solves both problems by:
- Making the orchestrator role explicit: "YOU ARE THE ORCHESTRATOR. DO NOT execute yourself."
- Injecting all necessary context into agent files: paths, constraints, specifications
- Enabling agents to read context and self-configure without tool invocations

**Performance Benefits** (lines 33-37):
- 100% file creation rate through explicit path injection
- <30% context usage by avoiding nested command prompts
- Hierarchical multi-agent coordination through clear role separation
- Parallel execution through independent context injection per agent

### 7. Case Study: Command-to-Command Anti-Pattern

**Source**: `/home/benjamin/.config/.claude/docs/concepts/patterns/behavioral-injection.md:618-638`

**Example Violation** (lines 618-638):
```markdown
❌ BAD - /orchestrate calling /plan command:

## Phase 2: Planning

I'll create an implementation plan for the researched topics.

SlashCommand tool invocation:
{
  "command": "/plan Implement OAuth 2.0 authentication"
}
```

**Why This Fails**:
1. Nests full /plan command prompt inside /orchestrate prompt (context bloat)
2. /plan command executes directly instead of delegating to planner-specialist
3. Breaks metadata-based context reduction (full plan content returned, not summary)
4. Prevents hierarchical patterns (flat command chaining)

This is EXACTLY the pattern that /coordinate is using with /implement.

## Recommendations

### 1. Replace SlashCommand Invocation with Agent Delegation (CRITICAL)

**Current Code** (coordinate.md:1089-1107):
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Execute implementation plan with automated testing and commits"
  timeout: 600000
  prompt: "
    Execute the /implement slash command with the following arguments:

    /implement \"$PLAN_PATH\"
    ...
  "
}
```

**Recommended Replacement**:
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Execute implementation with wave-based parallel execution"
  timeout: 600000
  prompt: "
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/implementer-coordinator.md

    Plan File: $PLAN_PATH
    Topic Path: $TOPIC_PATH
    Artifact Paths:
      - reports: $REPORTS_DIR
      - plans: $PLANS_DIR
      - summaries: $SUMMARIES_DIR
      - debug: $DEBUG_DIR
      - outputs: $OUTPUTS_DIR
      - checkpoints: $CHECKPOINT_DIR

    Execute implementation with:
    - Wave-based parallel execution for independent phases
    - Automated testing after each wave
    - Git commits for completed phases
    - Checkpoint state management

    Return: IMPLEMENTATION_COMPLETE: [summary]
  "
}
```

**Benefits**:
1. **Wave-Based Execution**: Enables parallel phase execution (40-60% time savings)
2. **Context Reduction**: Agent returns summary only (95% context reduction)
3. **Path Control**: Orchestrator maintains artifact path control
4. **Standard Compliance**: Follows Standard 11 behavioral injection pattern
5. **State Integration**: Works with state machine architecture
6. **Consistent Architecture**: Matches /orchestrate and /supervise patterns

### 2. Pre-Calculate All Artifact Paths (REQUIRED)

The implementer-coordinator agent expects pre-calculated paths. Add path calculation to /coordinate Phase 0:

```bash
# In Phase 0, after topic directory creation
REPORTS_DIR="${TOPIC_PATH}/reports"
PLANS_DIR="${TOPIC_PATH}/plans"
SUMMARIES_DIR="${TOPIC_PATH}/summaries"
DEBUG_DIR="${TOPIC_PATH}/debug"
OUTPUTS_DIR="${TOPIC_PATH}/outputs"
CHECKPOINT_DIR="${HOME}/.claude/data/checkpoints"

# Export for injection into agents
export REPORTS_DIR PLANS_DIR SUMMARIES_DIR DEBUG_DIR OUTPUTS_DIR CHECKPOINT_DIR
```

### 3. Update State Transition Logic

After implementer-coordinator returns, verify completion and transition state:

```bash
# Parse agent return value
if [[ "$AGENT_RESPONSE" =~ IMPLEMENTATION_COMPLETE:(.+) ]]; then
  IMPL_SUMMARY="${BASH_REMATCH[1]}"
  echo "✓ Implementation complete: $IMPL_SUMMARY"

  # Transition to test state
  sm_transition "$STATE_TEST"
  append_workflow_state "CURRENT_STATE" "$STATE_TEST"
else
  handle_state_error "Implementation did not complete successfully" 1
fi
```

### 4. Remove /implement Command Dependency

Update coordinate.md frontmatter to reflect agent delegation:

```yaml
---
allowed-tools: Task, TodoWrite, Bash, Read
command-type: primary
dependent-commands: research, plan, debug, test, document
dependent-agents: implementer-coordinator, research-specialist, plan-architect
---
```

Remove `/implement` from dependent-commands since we're using the agent directly.

### 5. Add Verification Checkpoint

After implementation phase, verify expected artifacts exist:

```bash
# Verify implementation artifacts created
if [ ! -f "$PLAN_PATH" ]; then
  handle_state_error "Plan file not found after implementation: $PLAN_PATH" 1
fi

# Check for implementation summary (if applicable)
SUMMARY_PATTERN="${SUMMARIES_DIR}/[0-9][0-9][0-9]_implementation_summary.md"
if ! ls $SUMMARY_PATTERN >/dev/null 2>&1; then
  echo "WARNING: No implementation summary found (non-critical)"
fi

echo "✓ Implementation artifacts verified"
```

### 6. Document the Pattern Change

Update /coordinate command guide (`.claude/docs/guides/coordinate-command-guide.md`) to document:

1. **Architecture Section**: Explain implementer-coordinator agent usage
2. **Wave-Based Execution**: Document parallel execution capabilities
3. **Path Injection**: Document artifact path requirements
4. **Standard Compliance**: Note Standard 11 compliance achieved
5. **Migration Notes**: Document change from /implement command to agent

### 7. Test the Fix

After implementing the fix, verify:

1. **Agent Delegation**: Confirm implementer-coordinator is invoked (not /implement command)
2. **Wave Execution**: Verify parallel phases run simultaneously when dependencies allow
3. **State Transitions**: Confirm state machine transitions work correctly
4. **Artifact Creation**: Verify all expected files created at correct paths
5. **Context Usage**: Monitor token consumption (<30% target)
6. **Time Savings**: Measure parallel execution time savings (40-60% target)

## References

### Primary Sources

1. **Current /coordinate Implementation**:
   - File: `/home/benjamin/.config/.claude/commands/coordinate.md`
   - Lines: 1089-1107 (SlashCommand invocation pattern)
   - Issue: Command-to-command invocation violates Standard 11

2. **Correct /orchestrate Pattern**:
   - File: `/home/benjamin/.config/.claude/commands/orchestrate.md`
   - Lines: 376-396 (implementer-coordinator invocation)
   - Shows: Proper behavioral injection pattern

3. **Correct /supervise Pattern**:
   - File: `/home/benjamin/.config/.claude/commands/supervise.md`
   - Lines: 260-273 (implementer-coordinator invocation)
   - Shows: Minimal agent delegation pattern

4. **Standard 11 Documentation**:
   - File: `/home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md`
   - Lines: 1173-1352 (Standard 11: Imperative Agent Invocation Pattern)
   - Lines: 312-332 (Command-to-command anti-pattern)
   - Defines: Required elements for agent invocation

5. **Behavioral Injection Pattern**:
   - File: `/home/benjamin/.config/.claude/docs/concepts/patterns/behavioral-injection.md`
   - Lines: 1-200 (Pattern definition and rationale)
   - Lines: 618-675 (Anti-patterns and case studies)
   - Explains: Why command-to-command invocation fails

6. **implementer-coordinator Agent**:
   - File: `/home/benjamin/.config/.claude/agents/implementer-coordinator.md`
   - Lines: 1-150 (Agent role and workflow)
   - Defines: Wave-based parallel execution coordinator

7. **Issue Description**:
   - File: `/home/benjamin/.config/.claude/specs/coordinage_implement.md`
   - Lines: 1-26 (Observed behavior showing /implement double invocation)

### Related Specifications

- **Spec 438**: YAML blocks wrapped in markdown code fences (different anti-pattern)
- **Spec 495**: /coordinate and /research delegation failures (multiple anti-patterns)
- **Spec 502**: Undermined imperative pattern discovery and fix
- **Spec 080**: /orchestrate Phase 0 improvements (location detection pattern)
- **Spec 620/630**: Bash block execution model and subprocess isolation

### Supporting Documentation

- `.claude/docs/guides/coordinate-command-guide.md` - Usage guide (needs update)
- `.claude/docs/guides/orchestration-best-practices.md` - Best practices guide
- `.claude/docs/architecture/state-based-orchestration-overview.md` - State machine architecture
