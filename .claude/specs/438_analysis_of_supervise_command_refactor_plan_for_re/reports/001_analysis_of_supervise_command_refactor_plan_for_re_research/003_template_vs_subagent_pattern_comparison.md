# Template vs Subagent Pattern Comparison

## Research Metadata
- **Topic**: Comparison of template-based generation vs subagent delegation for supervise command
- **Created**: 2025-10-23
- **Status**: Complete
- **Agent**: research-specialist
- **Report Type**: Pattern comparison and architecture analysis

## Related Reports
- **Overview Report**: [OVERVIEW.md](./OVERVIEW.md) - Complete analysis synthesis with architectural recommendations

## Executive Summary

The codebase uses two distinct patterns for command functionality: **subagent delegation (behavioral injection)** in orchestration commands and **template-based generation** in plan creation commands. Subagent delegation invokes specialized agents via the Task tool with context injection, enabling dynamic behavior, recursive coordination, and metadata-based context reduction (92-97%). Template-based generation uses static YAML templates with variable substitution, providing 60-80% faster execution for predictable patterns. For the supervise command, which requires adaptive multi-agent coordination with parallel research (2-4 agents), debugging loops (max 3 iterations), and hierarchical supervision, the subagent delegation pattern is the clear architectural fit.

## Research Questions
1. How does /orchestrate implement subagent delegation (behavioral injection)?
2. How does /plan-from-template implement template-based generation?
3. What are the advantages/disadvantages of each approach?
4. Which approach aligns better with supervise command requirements?

## Findings

### Subagent Delegation Pattern (Behavioral Injection)

**Definition and Core Mechanism** (`.claude/docs/concepts/patterns/behavioral-injection.md:7-29`):

Behavioral Injection is a pattern where orchestrating commands inject execution context, artifact paths, and role clarifications into agent prompts through file content rather than tool invocations. This transforms agents from autonomous executors into orchestrated workers that follow injected specifications.

The pattern separates:
- **Command role**: Orchestrator that calculates paths, manages state, delegates work
- **Agent role**: Executor that receives context via file reads and produces artifacts

**Implementation in /orchestrate** (`.claude/commands/orchestrate.md:1-300`):

1. **Explicit Role Declaration** (lines 40-58):
   - Command declares: "YOU MUST orchestrate... You are the WORKFLOW ORCHESTRATOR, not the executor"
   - Prohibits direct execution: "DO NOT execute research/planning/implementation yourself"
   - Requires Task tool delegation: "ONLY use Task tool to invoke specialized agents"

2. **Path Pre-Calculation** (behavioral-injection.md:63-79):
   - Orchestrator calculates all artifact paths before agent invocation
   - Creates topic directory structure: `specs/{NNN_topic}/{reports,plans,summaries,debug}`
   - Injects absolute paths into agent context

3. **Context Injection** (behavioral-injection.md:82-100):
   - Agents receive structured context via file reads, not SlashCommand invocations
   - Example: research-specialist receives `REPORT_PATH`, topic, constraints, output format
   - Prevents context bloat from nested command prompts (3000+ tokens each)

4. **Agent Invocation Pattern** (orchestrate.md:1005-1046):
   ```markdown
   Task tool invocation:
   {
     "subagent_type": "general-purpose",
     "description": "Research authentication patterns",
     "prompt": |
       Read and follow: .claude/agents/research-specialist.md

       **Research Topic**: OAuth patterns
       **Report Path**: /absolute/path/to/report.md
       **Context**: [injected specifications]
   }
   ```

5. **Parallel Execution** (orchestrate.md:1005-1017):
   - Multiple agents invoked simultaneously in SINGLE message
   - Independent context injection per agent enables parallelization
   - 40-60% time savings from concurrent research

**Key Benefits** (behavioral-injection.md:30-35):
- 100% file creation rate through explicit path injection
- <30% context usage by avoiding nested command prompts
- Hierarchical multi-agent coordination through clear role separation
- Parallel execution through independent context injection per agent

**Agent Templates Available** (`.claude/agents/README.md:87-270`):

11 specialized agents with restricted tool access:
- **research-specialist**: Research + report creation (Read, Write, Grep, Glob, WebSearch)
- **plan-architect**: Implementation planning (Read, Write, Grep, Glob)
- **code-writer**: Code implementation (Read, Write, Edit, Bash, TodoWrite)
- **test-specialist**: Testing and validation (Read, Bash, Grep, Glob)
- **debug-specialist**: Issue investigation (Read, Grep, Glob, Bash, WebSearch, Write)
- **doc-writer**: Documentation creation (Read, Write, Edit, Grep, Glob)
- **github-specialist**: PR management (Read, Grep, Glob, Bash)
- **complexity-estimator**: Context-aware analysis (Read, Grep, Glob)
- Plus 3 more specialized agents

**Critical Architecture Constraint** (orchestrate.md:10-36):
```markdown
<!-- /orchestrate MUST NEVER invoke other slash commands -->
<!-- FORBIDDEN TOOLS: SlashCommand -->
<!-- REQUIRED PATTERN: Task tool → Specialized agents -->
```

**Why This Matters**:
1. Context Bloat: SlashCommand expands entire command prompts (3000+ tokens each)
2. Broken Behavioral Injection: Commands invoked via SlashCommand cannot receive artifact path context
3. Lost Control: Orchestrator cannot customize agent behavior or inject topic numbers
4. Anti-Pattern Propagation: Sets bad example for future command development

### Template-Based Generation Pattern

**Definition and Core Mechanism** (`.claude/templates/README.md:1-10`):

Templates enable rapid plan generation for common feature types by providing pre-structured phases and tasks with variable substitution. Templates are written in YAML with the following structure:

```yaml
name: "Template Name"
description: "Brief description of what this template is for"
variables:
  - name: variable_name
    description: "What this variable represents"
    type: string|array|boolean
    required: true|false
    default: "optional default value"
phases:
  - name: "Phase Name"
    dependencies: []
    tasks:
      - "Task description with {{variable_name}} substitution"
      - "Loop example: {{#each array_var}}Item: {{this}}{{/each}}"
      - "Conditional: {{#if boolean_var}}Do this{{/if}}"
research_topics:
  - "Research topic with {{variable_name}}"
```

**Implementation in /plan-from-template** (`.claude/commands/plan-from-template.md:1-280`):

1. **Template Loading** (lines 40-77):
   - Check template exists in `.claude/templates/<name>.yaml`
   - Validate template structure using `.claude/lib/parse-template.sh`
   - Extract metadata and variable definitions via bash utilities

2. **Variable Collection** (lines 83-142):
   - Extract variable definitions: name, type, required, default
   - Prompt user for each variable value interactively
   - Validate based on type (string, array, boolean)
   - Build JSON object with collected variables

3. **Variable Substitution** (lines 146-170):
   - Call `.claude/lib/substitute-variables.sh` with template + variables JSON
   - Simple variables: `{{entity_name}}` → `User`
   - Arrays: `{{#each fields}}{{this}}{{/unless}}{{/each}}` → iteration
   - Conditionals: `{{#if use_auth}}Add authentication{{/if}}`

4. **Plan File Generation** (lines 174-217):
   - Determine next plan number via file system scan
   - Generate filename: `<specs-dir>/<number>_<feature-name>.md`
   - Write file with substituted content

**Available Templates** (`.claude/templates/README.md:52-69`):

11 standard templates across 8 categories:
- **feature**: crud-feature.yaml (CRUD operations)
- **backend**: api-endpoint.yaml (REST endpoints)
- **refactoring**: refactoring.yaml, refactor-consolidation.yaml
- **debugging**: debug-workflow.yaml
- **documentation**: documentation-update.yaml
- **testing**: test-suite.yaml
- **migration**: migration.yaml
- **research**: research-report.yaml

**Example Template** (`.claude/templates/crud-feature.yaml:1-88`):

```yaml
name: "CRUD Feature Implementation"
description: "Template for implementing Create, Read, Update, Delete operations"
category: "feature"
complexity_level: "medium-high"
estimated_time: "8-12 hours"
variables:
  - name: entity_name
    type: string
    required: true
  - name: fields
    type: array
    required: true
  - name: use_auth
    type: boolean
    default: "true"
phases:
  - name: "Database Schema and Models"
    dependencies: []
    tasks:
      - "Create database migration for {{entity_name}} table"
      - "Define {{entity_name}} schema with fields: {{#each fields}}{{this}}{{/unless}}{{/each}}"
      # ... 4 more tasks
  - name: "Backend CRUD API"
    dependencies: [1]
    tasks:
      - "Implement Create{{entity_name}} endpoint (POST /api/{{entity_name}}s)"
      # ... 8 more tasks
```

**Key Benefits**:
- **Speed**: 60-80% faster than manual plan creation (plan-from-template.md:274)
- **Consistency**: Standardized structure ensures completeness
- **Predictability**: Same pattern produces same output
- **Simplicity**: No agent coordination overhead

**Limitations**:
- **Static**: Cannot adapt to codebase context dynamically
- **No Research**: Cannot discover existing patterns via Grep/Glob
- **No Validation**: Cannot verify if pattern fits project architecture
- **No Customization**: One-size-fits-all approach

### Comparison Analysis

| Aspect | Subagent Delegation | Template-Based Generation |
|--------|---------------------|---------------------------|
| **Flexibility** | High - agents adapt to codebase | Low - static YAML structure |
| **Context Awareness** | Dynamic - discovers patterns via Grep/Glob | None - pre-defined content only |
| **Execution Speed** | Moderate - agent invocation overhead | Fast - simple file operations |
| **Parallelization** | Yes - multiple agents concurrently | No - sequential file generation |
| **Reusability** | High - agents work across domains | Medium - templates domain-specific |
| **Maintainability** | High - agents + patterns documented separately | Medium - templates need updates |
| **Context Usage** | <30% via metadata extraction | Minimal - no context passing |
| **File Creation Rate** | 100% via path injection | 100% via direct write |
| **Error Recovery** | Sophisticated - retry, fallback, escalation | Simple - validation errors only |
| **Recursive Coordination** | Yes - supervisors manage sub-supervisors | No - single-level only |
| **Debugging Support** | Yes - conditional debugging loops | No - static plan generation |
| **Research Integration** | Built-in - parallel research phase | Manual - user provides context |

**Performance Metrics**:

Subagent Delegation (from behavioral-injection.md:309-338):
- Context reduction: 92-97% through metadata-only passing
- Time savings: 40-60% from parallel execution
- File creation: 100% (before: 60-80%)
- Hierarchical coordination: 10+ agents across 3 levels

Template-Based Generation (from plan-from-template.md:274):
- Speed improvement: 60-80% faster than manual planning
- Context usage: Negligible (no agent coordination)
- File creation: 100% (direct file write)
- Scalability: Single-level only

**Use Case Alignment**:

**Template-Based Generation Best For**:
- Common, well-understood patterns (CRUD, API endpoints, refactoring)
- Predictable workflows with fixed structure
- Rapid prototyping and initial plan creation
- Teams with established conventions

**Subagent Delegation Best For**:
- Complex workflows requiring codebase analysis
- Adaptive behavior based on discovered patterns
- Multi-phase orchestration (research → plan → implement → debug)
- Hierarchical coordination with multiple agents
- Parallel execution of independent tasks
- Error recovery and retry logic

### Architecture Alignment for Supervise Command

**Supervise Command Requirements** (from 001_supervise_command_evolution.md context):

1. **Multi-Agent Coordination**: Manage 2-4 research agents in parallel
2. **Adaptive Planning**: Respond to complexity and test failures
3. **Debugging Loops**: Conditional debugging phase (max 3 iterations)
4. **Error Recovery**: Retry logic with exponential backoff
5. **Hierarchical Supervision**: Potential recursive sub-supervisors
6. **Context Management**: Metadata-based passing for <30% usage
7. **Checkpoint Recovery**: Save/restore workflow state
8. **Dynamic Behavior**: Adapt to codebase patterns

**Pattern Fit Analysis**:

| Requirement | Template Support | Subagent Support |
|-------------|------------------|------------------|
| Multi-agent coordination | ✗ No agent invocation | ✓ Task tool with context injection |
| Adaptive planning | ✗ Static YAML | ✓ Agent analysis + revise command |
| Debugging loops | ✗ No conditional logic | ✓ Conditional phase invocation |
| Error recovery | ✗ Simple validation only | ✓ Retry + fallback strategies |
| Hierarchical supervision | ✗ Single-level only | ✓ Recursive supervision pattern |
| Context management | N/A No context passing | ✓ Metadata extraction (92-97% reduction) |
| Checkpoint recovery | ✗ No state management | ✓ Checkpoint-utils.sh integration |
| Dynamic behavior | ✗ Pre-defined templates | ✓ Codebase discovery via Grep/Glob |

**Architectural Precedent**:

/orchestrate (orchestrate.md:38-64) provides the canonical implementation:
- Pure orchestration model: orchestrator coordinates, agents execute
- Explicit role declaration prevents direct execution
- Path pre-calculation ensures 100% file creation
- Parallel research phase (2-4 agents) for 40-60% time savings
- Conditional debugging phase enters only if tests fail
- Checkpoint-based recovery enables resume after interruption
- Metadata-based context passing achieves <30% context usage

**Critical Architecture Constraint** (orchestrate.md:10-36):

The codebase explicitly forbids SlashCommand invocations in orchestration commands:
```markdown
/orchestrate MUST NEVER invoke other slash commands
FORBIDDEN TOOLS: SlashCommand
REQUIRED PATTERN: Task tool → Specialized agents
```

This constraint exists because:
1. SlashCommand expands entire command prompts (3000+ tokens)
2. Breaks behavioral injection (no artifact path context)
3. Prevents orchestrator customization (lost control)
4. Sets anti-pattern precedent

**Therefore**: Any orchestration command (including supervise) MUST use subagent delegation.

### Hybrid Approach Consideration

**Could supervise use templates for agent prompt generation?**

**Analysis**:

Templates could theoretically generate agent prompt structures, but this introduces:

1. **Indirection Complexity**: Template generates prompt → command injects context → agent executes
2. **Maintenance Burden**: Agent definitions in `.claude/agents/*.md` + templates = duplication
3. **Loss of Flexibility**: Templates cannot adapt to codebase findings mid-workflow
4. **Architectural Inconsistency**: /orchestrate uses direct agent files, not templates

**Recommendation**: No hybrid approach. Use pure subagent delegation with agent definitions.

**Rationale**:
- Agent files (`.claude/agents/*.md`) already provide reusable behavior definitions
- Behavioral injection pattern enables context customization without templates
- Direct agent file reads simpler than template → agent transformation
- Consistency with /orchestrate architecture

## Recommendations

### Primary Recommendation: Subagent Delegation Pattern

**The supervise command MUST use the subagent delegation (behavioral injection) pattern** for the following reasons:

1. **Architectural Consistency**: Aligns with /orchestrate pattern (the canonical orchestration command)
2. **Multi-Agent Coordination**: Enables parallel research phase (2-4 agents) with 40-60% time savings
3. **Adaptive Behavior**: Agents discover codebase patterns via Grep/Glob dynamically
4. **Error Recovery**: Sophisticated retry logic with exponential backoff and fallback strategies
5. **Hierarchical Supervision**: Supports recursive sub-supervisors for complex workflows
6. **Context Efficiency**: Metadata extraction achieves 92-97% context reduction
7. **Checkpoint Recovery**: Integrates with checkpoint-utils.sh for resumable workflows
8. **Debugging Support**: Conditional debugging loops (max 3 iterations) based on test results
9. **100% File Creation**: Path injection guarantees artifacts in correct locations
10. **Forbidden Alternative**: SlashCommand invocations explicitly prohibited in orchestration commands

### Implementation Guidance

**Phase 0: Role Declaration** (behavioral-injection.md:41-60):
```markdown
## YOUR ROLE

You are the ORCHESTRATOR for this workflow. Your responsibilities:

1. Calculate artifact paths and workspace structure
2. Invoke specialized subagents via Task tool
3. Aggregate and forward subagent results
4. DO NOT execute implementation work yourself using Read/Grep/Write/Edit tools

YOU MUST NOT:
- Execute research directly (use research-specialist agent)
- Create plans directly (use plan-architect agent)
- Implement code directly (use code-writer agent)
- Write documentation directly (use doc-writer agent)
```

**Agent Invocation Pattern** (orchestrate.md:1086-1110):
```markdown
Task {
  "subagent_type": "general-purpose",
  "description": "Research topic X",
  "prompt": |
    Read and follow: .claude/agents/research-specialist.md

    **ABSOLUTE REQUIREMENT - File Creation is Your Primary Task**

    **Research Topic**: [topic]
    **Report Path**: [absolute path from Phase 0]
    **Context**: [injected specifications]
}
```

**Parallel Execution** (orchestrate.md:1005-1017):
- Invoke ALL research agents in parallel in SINGLE message
- Independent context injection per agent
- Wait for all completions before proceeding to next phase

**Metadata Forwarding** (forward-message.md:59-115):
- DO NOT re-summarize subagent results
- FORWARD subagent metadata objects directly
- Minimal transition text only (20-50 tokens)
- Preserves 100% precision from agents

### Specific Agents for Supervise Command

Based on supervise requirements, use these agents:

1. **research-specialist** (2-4 agents in parallel): Research phase
2. **plan-architect**: Planning phase with research report paths
3. **implementer-coordinator**: Implementation phase with wave-based execution
4. **test-specialist**: Testing phase execution
5. **debug-specialist**: Conditional debugging phase (only if tests fail)
6. **doc-writer**: Documentation phase
7. **github-specialist**: Optional PR creation phase

### Template Usage: Limited Scope

Templates should ONLY be used for:
- Checkpoint file structure (YAML format)
- Error recovery message templates (fixed strings)
- Progress reporting format (fixed strings)

Templates should NOT be used for:
- Agent prompt generation (use agent files directly)
- Workflow orchestration logic (use command markdown)
- Dynamic content generation (use agents)

### Migration Path

If supervise currently uses any template-based logic:

1. **Identify Static Content**: Extract fixed strings to minimal templates
2. **Extract Agent Behaviors**: Move agent logic to `.claude/agents/*.md` files
3. **Implement Behavioral Injection**: Use Task tool with context injection
4. **Add Verification Checkpoints**: Verify file creation after each phase
5. **Integrate Metadata Extraction**: Use forward message pattern
6. **Test Parallel Execution**: Verify research phase parallelization
7. **Validate Error Recovery**: Test retry logic and fallback strategies

## References

### Pattern Documentation
- `.claude/docs/concepts/patterns/behavioral-injection.md` - Complete pattern definition (352 lines)
- `.claude/docs/concepts/patterns/forward-message.md` - Metadata forwarding pattern (331 lines)
- `.claude/docs/concepts/patterns/metadata-extraction.md` - Context reduction technique
- `.claude/docs/concepts/patterns/hierarchical-supervision.md` - Recursive coordination

### Command Implementations
- `.claude/commands/orchestrate.md` - Canonical orchestration implementation (lines 1-300+ analyzed)
- `.claude/commands/plan-from-template.md` - Template-based generation reference (280 lines)
- `.claude/commands/plan.md` - Manual planning with agent delegation
- `.claude/commands/implement.md` - Implementation with agent coordination

### Agent Definitions
- `.claude/agents/README.md` - Agent architecture overview (646 lines)
- `.claude/agents/research-specialist.md` - Research agent with file creation protocol (646 lines)
- `.claude/agents/plan-architect.md` - Planning agent
- `.claude/agents/code-writer.md` - Implementation agent
- `.claude/agents/debug-specialist.md` - Debugging agent

### Template System
- `.claude/templates/README.md` - Template system documentation (287 lines)
- `.claude/templates/crud-feature.yaml` - Example template structure (88 lines)
- `.claude/lib/parse-template.sh` - Template parsing utility
- `.claude/lib/substitute-variables.sh` - Variable substitution engine

### Utility Libraries
- `.claude/lib/checkpoint-utils.sh` - Checkpoint save/restore operations
- `.claude/lib/error-handling.sh` - Retry logic and error recovery
- `.claude/lib/metadata-extraction.sh` - Metadata parsing functions
- `.claude/lib/unified-logger.sh` - Structured logging

### Architecture Standards
- `.claude/docs/reference/command_architecture_standards.md` - Command development standards
- `.claude/docs/guides/command-development-guide.md` - Command creation guide (lines 1-150+ analyzed)
- `.claude/docs/guides/agent-development-guide.md` - Agent creation patterns
- `CLAUDE.md` - Project configuration and standards index
