# Behavioral Injection Pattern

[Used by: /orchestrate, /implement, /plan, /report, /debug, all coordinating commands]

Commands inject context into agents via file reads instead of SlashCommand tool invocations, enabling hierarchical multi-agent patterns and preventing direct execution.

## Definition

Behavioral Injection is a pattern where orchestrating commands inject execution context, artifact paths, and role clarifications into agent prompts through file content rather than tool invocations. This transforms agents from autonomous executors into orchestrated workers that follow injected specifications.

The pattern separates:
- **Command role**: Orchestrator that calculates paths, manages state, delegates work
- **Agent role**: Executor that receives context via file reads and produces artifacts

## Rationale

### Why This Pattern Matters

Commands that invoke other commands using the SlashCommand tool create two critical problems:

1. **Role Ambiguity**: When a command says "I'll research the topic", Claude interprets this as "I should execute research directly using Read/Grep/Write tools" instead of "I should orchestrate agents to research". This prevents hierarchical multi-agent patterns.

2. **Context Bloat**: Command-to-command invocations nest full command prompts within parent prompts, causing exponential context growth and breaking metadata-based context reduction.

Behavioral Injection solves both problems by:
- Making the orchestrator role explicit: "YOU ARE THE ORCHESTRATOR. DO NOT execute yourself."
- Injecting all necessary context into agent files: paths, constraints, specifications
- Enabling agents to read context and self-configure without tool invocations

### Problems Solved

- 100% file creation rate through explicit path injection
- <30% context usage by avoiding nested command prompts
- Hierarchical multi-agent coordination through clear role separation
- Parallel execution through independent context injection per agent

## Implementation

### Core Mechanism

**Phase 0: Role Clarification**

Every orchestrating command begins with explicit role declaration:

```markdown
## YOUR ROLE

You are the ORCHESTRATOR for this workflow. Your responsibilities:

1. Calculate artifact paths and workspace structure
2. Invoke specialized subagents via Task tool
3. Aggregate and forward subagent results
4. DO NOT execute implementation work yourself using Read/Grep/Write/Edit tools

YOU MUST NOT:
- Execute research directly (use research-specialist agent)
- Create plans directly (use planner-specialist agent)
- Implement code directly (use implementer agent)
- Write documentation directly (use doc-writer agent)
```

**Path Pre-Calculation**

Before invoking any agent, calculate and validate all paths:

```bash
# Example from /orchestrate Phase 0
EXECUTE NOW - Calculate Paths:

1. Determine project root: /home/benjamin/.config
2. Find deepest directory encompassing workflow scope
3. Calculate next topic number: specs/NNN_topic/
4. Create topic directory structure:
   mkdir -p specs/027_authentication/{reports,plans,summaries,debug}
5. Assign artifact paths:
   REPORTS_DIR="specs/027_authentication/reports/"
   PLANS_DIR="specs/027_authentication/plans/"
   SUMMARIES_DIR="specs/027_authentication/summaries/"
```

**Context Injection via File Content**

Inject context into agent prompts through structured data:

```yaml
# Injected into research-specialist agent prompt
research_context:
  topic: "OAuth 2.0 authentication patterns"
  scope: "Focus on implementation patterns for Node.js APIs"
  constraints:
    - "Must support refresh tokens"
    - "Must integrate with existing session management"
  output_path: "specs/027_authentication/reports/001_oauth_patterns.md"
  output_format:
    sections:
      - "OAuth 2.0 Flow Overview"
      - "Implementation Patterns"
      - "Security Considerations"
      - "Integration Strategy"
```

### Code Example

Real implementation from Plan 080 - /orchestrate Phase 0:

```markdown
## Phase 0: Project Location Determination

EXECUTE NOW:

1. YOUR ROLE: You are the ORCHESTRATOR, not the executor
2. DO NOT use Read/Grep/Write to explore codebase yourself
3. ONLY use Task tool to invoke location-specialist agent

INVOKE AGENT - location-specialist:

Task tool invocation:
{
  "agent": "location-specialist",
  "task": "Analyze workflow '<user_request>' and determine project location",
  "context": {
    "workflow_request": "<full user request here>",
    "current_directory": "/home/benjamin/.config",
    "requirements": [
      "Find deepest directory encompassing affected components",
      "Calculate next topic number for specs/ directory",
      "Create topic directory structure: NNN_topic/{reports,plans,summaries,debug}",
      "Return topic_path and artifact_paths for injection into subsequent agents"
    ]
  }
}

EXPECTED RETURN (metadata only):
{
  "topic_path": "/path/to/project/specs/027_authentication/",
  "topic_number": "027",
  "artifact_paths": {
    "reports": "{topic_path}/reports/",
    "plans": "{topic_path}/plans/",
    "summaries": "{topic_path}/summaries/",
    "debug": "{topic_path}/debug/"
  },
  "summary": "50-word summary of location analysis and directory structure created"
}
```

After receiving location context, inject into all subsequent agents:

```markdown
## Phase 1: Research

FOR EACH research topic, invoke research-specialist with injected context:

CONTEXT INJECTION (prepend to agent prompt):
---
ARTIFACT LOCATION (REQUIRED):
- Save all reports to: specs/027_authentication/reports/
- Use topic number prefix: 027
- Follow naming: {topic_number}_{topic_name}.md

PROJECT CONTEXT:
- Topic path: specs/027_authentication/
- Related components: [list from location-specialist]
---

Task tool invocation:
{
  "agent": "research-specialist",
  "task": "Research OAuth 2.0 authentication patterns for Node.js",
  "context": "<injected context above + research requirements>"
}
```

### Usage Context

**When to Apply:**
- All commands that coordinate multiple agents (orchestrators)
- Commands that manage workflows with file creation
- Any command scoring <90 on audit-execution-enforcement.sh

**When Not to Apply:**
- Simple utility commands that don't invoke agents
- Agents themselves (they receive injected context, don't inject it)
- Commands that only read and analyze (no file creation)

## Anti-Patterns

### Example Violation 1: Command-to-Command Invocation

```markdown
❌ BAD - /orchestrate calling /plan command:

## Phase 2: Planning

I'll create an implementation plan for the researched topics.

SlashCommand tool invocation:
{
  "command": "/plan Implement OAuth 2.0 authentication"
}
```

**Why This Fails:**
1. Nests full /plan command prompt inside /orchestrate prompt (context bloat)
2. /plan command executes directly instead of delegating to planner-specialist
3. Breaks metadata-based context reduction (full plan content returned, not summary)
4. Prevents hierarchical patterns (flat command chaining)

### Example Violation 2: Direct Execution

```markdown
❌ BAD - Command executing work directly:

## Phase 1: Research

I'll research OAuth 2.0 patterns using Read and Grep tools.

Read tool: /path/to/existing/auth/code.js
Grep tool: pattern="OAuth" path="src/"
```

**Why This Fails:**
1. Command acts as executor instead of orchestrator
2. No agent delegation means no metadata extraction
3. Cannot parallelize research (single command context)
4. Misses behavioral injection of paths and constraints

### Example Violation 3: Ambiguous Role

```markdown
❌ BAD - No role clarification:

## /plan Command

I'll analyze the requirements and create an implementation plan.

First, let me explore the codebase...
```

**Why This Fails:**
1. "I'll create" is ambiguous - direct execution or agent delegation?
2. No explicit "DO NOT execute yourself" instruction
3. Claude defaults to direct execution using Read/Grep/Write
4. Prevents hierarchical multi-agent patterns

## Testing Validation

### Validation Script

```bash
#!/bin/bash
# .claude/tests/validate_behavioral_injection.sh

COMMAND_FILE="$1"

echo "Validating behavioral injection pattern in $COMMAND_FILE..."

# Check 1: Role clarification present
if ! grep -q "YOU ARE THE ORCHESTRATOR" "$COMMAND_FILE" && \
   ! grep -q "YOUR ROLE:" "$COMMAND_FILE"; then
  echo "❌ MISSING: Role clarification (Phase 0)"
  exit 1
fi

# Check 2: Anti-execution instructions present
if ! grep -q "DO NOT execute.*yourself" "$COMMAND_FILE"; then
  echo "❌ MISSING: Anti-execution instructions"
  exit 1
fi

# Check 3: No SlashCommand invocations to other commands
if grep -q "SlashCommand.*/(plan|implement|debug|report|document)" "$COMMAND_FILE"; then
  echo "❌ VIOLATION: Command-to-command invocation detected"
  exit 1
fi

# Check 4: Path pre-calculation present
if ! grep -q "EXECUTE NOW.*Calculate Paths" "$COMMAND_FILE"; then
  echo "❌ MISSING: Path pre-calculation"
  exit 1
fi

# Check 5: Context injection structure present
if ! grep -q "CONTEXT INJECTION" "$COMMAND_FILE" && \
   ! grep -q "context:" "$COMMAND_FILE"; then
  echo "⚠️  WARNING: No explicit context injection found"
fi

echo "✓ Behavioral injection pattern validated"
```

### Expected Results

**Compliant Command:**
- Audit score ≥90/100 on audit-execution-enforcement.sh
- Role clarification in Phase 0
- All agent invocations use Task tool (not SlashCommand)
- Path pre-calculation before file operations
- Context injection structure for agents

**Non-Compliant Command:**
- Audit score <90/100
- Missing role clarification
- SlashCommand invocations to /plan, /implement, /debug
- Direct execution using Read/Grep/Write instead of agents

## Performance Impact

### Measurable Improvements

**File Creation Rate:**
- Before: 60-80% (commands creating files in wrong locations)
- After: 100% (explicit path injection ensures correct locations)

**Context Reduction:**
- Before: 80-100% context usage (nested command prompts)
- After: <30% context usage (metadata-only passing between agents)

**Parallelization:**
- Before: Impossible (sequential command chaining)
- After: 40-60% time savings (independent agents run in parallel)

**Hierarchical Coordination:**
- Before: Flat command chaining (max 4 agents)
- After: Recursive supervision (10+ agents across 3 levels)

### Real-World Metrics (Plan 080)

**Before behavioral injection:**
- /orchestrate invoked /plan command → /plan invoked planner-specialist
- Context usage: 85% (full /plan prompt nested in /orchestrate)
- File creation: 7/10 plans in correct location (70%)

**After behavioral injection:**
- /orchestrate invoked planner-specialist directly with injected paths
- Context usage: 25% (metadata-only return from planner)
- File creation: 10/10 plans in correct location (100%)

## Related Patterns

- [Metadata Extraction](./metadata-extraction.md) - Complements behavioral injection by reducing context after agent execution
- [Hierarchical Supervision](./hierarchical-supervision.md) - Enabled by behavioral injection's clear role separation
- [Verification and Fallback](./verification-fallback.md) - Uses injected paths for verification checkpoints
- [Parallel Execution](./parallel-execution.md) - Requires independent context injection per agent

## See Also

- [Command Architecture Standards](../../reference/command-architecture-standards.md) - Phase 0 requirements
- [Creating Commands Guide](../../guides/creating-commands.md) - Orchestrator patterns
- [Hierarchical Agents Guide](../hierarchical-agents.md) - Agent coordination architecture
- [Orchestration Guide](../../workflows/orchestration-guide.md) - Full workflow patterns
