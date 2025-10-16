# Claude Code Custom Agent Invocation: Workarounds and Limitations Research Report

## Metadata
- **Date**: 2025-10-01
- **Scope**: Analysis of custom agent invocation mechanisms in Claude Code, Task tool limitations, and available workarounds
- **Primary Directory**: `.claude/`
- **Files Analyzed**:
  - `.claude/agents/plan-architect.md`
  - `.claude/commands/plan.md`
  - `.claude/commands/orchestrate.md`
- **Research Sources**:
  - Claude Code official documentation (docs.claude.com)
  - GitHub issues (#5185, #4728, #4601, #8697)
  - Community resources (ClaudeLog, Medium articles, developer blogs)
- **GitHub Issue Created**: [#8697](https://github.com/anthropics/claude-code/issues/8697)

## Executive Summary

This research investigates the current state of custom agent invocation in Claude Code, specifically addressing the inability to use custom agents from `.claude/agents/` as `subagent_type` values in the Task tool.

**Key Findings**:
1. The Task tool only supports 3 built-in agent types: `general-purpose`, `statusline-setup`, and `output-style-setup`
2. Custom agents in `.claude/agents/` are discoverable via `/agents` UI but not invokable via Task tool's `subagent_type` parameter
3. Natural language explicit invocation is the current recommended pattern for custom agents
4. No existing workaround provides both tool restriction enforcement AND programmatic invocation
5. Feature request #8697 addresses a genuine gap in the Claude Code architecture

**Impact**: Slash commands referencing custom agents (e.g., `plan-architect`, `research-specialist`) cannot enforce tool restrictions or use structured Task tool invocation, limiting workflow orchestration capabilities.

## Background

### Problem Context

The user's `.claude/agents/plan-architect.md` agent definition includes:
```yaml
---
allowed-tools: Read, Write, Grep, Glob, WebSearch
description: Specialized in creating detailed, phased implementation plans
---
```

Slash commands in `.claude/commands/` reference this agent:
```yaml
# In /plan command
Task {
  subagent_type: "plan-architect"  # ← This fails
  description: "Create implementation plan"
  prompt: "..."
}
```

**Error**: `Agent type 'plan-architect' not found.`

### Architecture Gap

Claude Code supports:
- ✅ Custom agent definitions in `.claude/agents/*.md`
- ✅ Agent discovery via `/agents` command
- ✅ Natural language agent invocation ("Use the X agent to...")
- ❌ Custom agents as Task tool `subagent_type` values
- ❌ Tool restriction enforcement from agent frontmatter
- ❌ Programmatic agent invocation with structured parameters

## Current State Analysis

### How Custom Agents Work

**Agent Definition** (`.claude/agents/plan-architect.md`):
```markdown
---
allowed-tools: Read, Write, Grep, Glob, WebSearch
description: Specialized in creating detailed, phased implementation plans
---

# Plan Architect Agent

I am a specialized agent focused on creating comprehensive, phased implementation plans...
```

**Agent Discovery**:
- Files scanned from `~/.claude/agents/` (user-level) and `.claude/agents/` (project-level)
- Project-level agents take precedence over user-level
- Registered via `/agents` command interface
- Requires restart for changes to take effect

**Agent Invocation Methods**:

1. **Automatic Delegation**: Claude analyzes task and delegates to appropriate agent based on description
2. **Explicit Invocation**: Natural language mention ("Use the plan-architect agent to...")
3. **Task Tool** (built-in types only): Structured invocation with `subagent_type` parameter

### Task Tool Implementation

**Built-in Agent Types** (hardcoded):
```typescript
// Inferred from documentation and behavior
type SubagentType =
  | "general-purpose"
  | "statusline-setup"
  | "output-style-setup"
```

**Usage Pattern**:
```yaml
Task {
  subagent_type: "general-purpose",
  description: "5-10 word task description",
  prompt: "Detailed task instructions..."
}
```

**Capabilities**:
- Separate context window per task
- Parallel execution (up to 10 simultaneous tasks)
- Tool access inheritance from main agent
- Structured output handling

**Limitations**:
- No dynamic agent type registration
- No `.claude/agents/` integration
- No tool restriction enforcement per agent

### Related GitHub Issues

**Issue #5185 & #4728** (CLOSED - v1.0.84):
- **Problem**: Custom agents not appearing in `/agents` UI
- **Root Causes**:
  - ripgrep installation/configuration issues
  - Malformed agent markdown files
  - Multiple Claude Code installations
  - Invalid `.md` files in agent directories (e.g., `README.md`, `.github/` files)
- **Resolution**: Improved agent parsing and ripgrep handling

**Issue #4601** (OPEN):
- **Problem**: Agents must be created via `/agents` UI, not programmatically
- **Request**: Dynamic agent creation via natural language when `dangerously-skip-permissions` enabled
- **Status**: Under consideration
- **Difference**: This is about runtime agent creation, not Task tool integration

**Issue #8697** (OPEN - Created during this research):
- **Problem**: Task tool doesn't support custom agents as `subagent_type` values
- **Request**: Auto-discover `.claude/agents/*.md` and register as valid `subagent_type` options
- **Status**: Novel feature request, no prior discussion
- **Impact**: Would enable tool-restricted, programmatically invokable custom agents

## Workarounds Analysis

### Workaround 1: Natural Language Explicit Invocation ⭐ (Recommended)

**Implementation**:
```markdown
# In .claude/commands/plan.md

Use the plan-architect agent to create a detailed implementation plan for $ARGUMENTS

Instructions for the plan-architect agent:
- Read research findings from provided reports
- Follow project standards in CLAUDE.md
- Create multi-phase plan with testing strategy
- Output to specs/plans/NNN_feature_name.md
```

**How It Works**:
1. Claude Code parses the prompt and detects agent name mention
2. Searches `.claude/agents/plan-architect.md` for agent definition
3. Automatically delegates task to that agent
4. Agent executes with its own context window

**Invocation Patterns**:
- "Use the [agent-name] agent to [task]"
- "Have the [agent-name] subagent [action]"
- "Ask the [agent-name] to [objective]"
- "Get [agent-name] to [goal]"

**Advantages**:
- ✅ Works with current Claude Code implementation
- ✅ No code changes required
- ✅ Natural, flexible syntax
- ✅ Supports all agent features (custom prompts, separate context)

**Limitations**:
- ❌ No tool restriction enforcement from `allowed-tools` frontmatter
- ❌ Less structured/programmatic than Task tool
- ❌ Relies on Claude's automatic agent selection (could select wrong agent)
- ❌ No parallel execution control
- ❌ Limited error handling

**Use Cases**:
- Simple agent delegation from slash commands
- Interactive workflows where user can intervene
- Tasks where tool restrictions aren't critical

**Example in Practice**:
```markdown
# .claude/commands/review.md
---
description: Code review with specialized agent
---

I'll review your code changes using our specialized code-reviewer agent.

Use the code-reviewer agent to analyze the git diff and provide:
- Code quality assessment
- Security vulnerability scan
- Performance optimization suggestions
- Best practices compliance check

Report findings in a structured format.
```

### Workaround 2: Embed Agent Instructions Inline

**Implementation**:
```yaml
Task {
  subagent_type: "general-purpose",
  description: "Create implementation plan",
  prompt: "
    You are a specialized plan architect agent focused on creating
    comprehensive, phased implementation plans.

    Core Capabilities:
    - Create multi-phase implementation plans
    - Break complex features into manageable tasks
    - Define clear success criteria and testing strategies

    [... paste full agent instructions from plan-architect.md ...]

    Your task: Create plan for [feature]

    Requirements:
    - Multi-phase structure with specific tasks
    - Testing strategy for each phase
    - /implement compatibility (checkbox format)
  "
}
```

**Advantages**:
- ✅ Works with current Task tool
- ✅ Programmatic, structured invocation
- ✅ Supports parallel execution
- ✅ Full Task tool capabilities (timeout, description, etc.)

**Limitations**:
- ❌ Duplicates agent definitions (maintenance burden)
- ❌ No tool restriction enforcement
- ❌ Agent instructions must be manually synced
- ❌ Verbose command definitions
- ❌ Loses separation of concerns

**Use Cases**:
- Temporary workaround until feature #8697 is implemented
- Commands that need Task tool features (parallel execution, timeouts)
- Workflows requiring strict structured invocation

**Implementation Strategy**:
```markdown
# .claude/commands/plan.md

# Read agent definition at runtime
1. Use Read tool to load .claude/agents/plan-architect.md
2. Extract agent instructions from markdown content
3. Inject into Task prompt
4. Invoke Task tool with general-purpose type
```

### Workaround 3: Use `/agents` for Discovery + Explicit Invocation

**Implementation**:
```markdown
# .claude/commands/plan.md

Let me create an implementation plan for: $ARGUMENTS

I will use the plan-architect agent that specializes in creating structured,
phased implementation plans following project standards.

Use the plan-architect agent to analyze requirements and generate the plan.
```

**Workflow**:
1. User creates agents via `/agents` UI (ensures proper registration)
2. Slash commands mention agents by name in prompts
3. Claude auto-selects the registered agent based on name/description match

**Advantages**:
- ✅ Leverages official agent registration mechanism
- ✅ Clear agent discovery and management via `/agents` UI
- ✅ Project-level and user-level agent support
- ✅ Agent modifications reflected after restart

**Limitations**:
- ❌ Requires manual agent creation via UI
- ❌ No tool restriction enforcement
- ❌ Less control over agent selection
- ❌ Restart required for agent updates

**Use Cases**:
- Teams with established agent libraries
- Projects where agents are infrequently modified
- Workflows prioritizing simplicity over programmatic control

### Workaround 4: SlashCommand Tool from Within Agents (Reverse Pattern)

**Implementation**:
```markdown
# .claude/agents/orchestrator.md
---
name: orchestrator
description: Coordinates multi-phase workflows using slash commands
allowed-tools: SlashCommand, TodoWrite, Read
---

# Orchestrator Agent

You orchestrate complex workflows by invoking slash commands in sequence:

1. Research Phase: Use SlashCommand tool to invoke /report for topic research
2. Planning Phase: Use SlashCommand tool to invoke /plan with research results
3. Implementation Phase: Use SlashCommand tool to invoke /implement with plan
4. Documentation Phase: Use SlashCommand tool to invoke /document for updates

For each phase:
- Track progress with TodoWrite
- Pass context between commands
- Handle errors gracefully
- Report status to user
```

**Usage**:
```
User: "Implement new authentication feature"

Main Agent: Use the orchestrator agent to coordinate this workflow

Orchestrator Agent:
  1. Executes: SlashCommand("/report authentication patterns")
  2. Executes: SlashCommand("/plan auth feature [report-path]")
  3. Executes: SlashCommand("/implement [plan-path]")
  4. Executes: SlashCommand("/document auth implementation")
```

**Advantages**:
- ✅ Inverts the pattern: agents orchestrate commands (not commands invoking agents)
- ✅ Enables complex multi-command workflows
- ✅ Centralized workflow logic in agent definition
- ✅ Reusable orchestration patterns

**Limitations**:
- ❌ Conceptually different from original goal
- ❌ Requires SlashCommand tool access (may not be available in all contexts)
- ❌ Adds orchestration complexity to agent definitions
- ❌ Still no tool restriction enforcement

**Use Cases**:
- Complex workflows with multiple command sequences
- Standardized development pipelines (research → plan → implement → document)
- Repeatable multi-step processes

### Workaround Comparison Matrix

| Feature | Workaround 1 | Workaround 2 | Workaround 3 | Workaround 4 |
|---------|-------------|-------------|-------------|-------------|
| **Natural Invocation** | ✅ | ❌ | ✅ | ✅ |
| **Programmatic** | ❌ | ✅ | ❌ | ✅ |
| **Tool Restrictions** | ❌ | ❌ | ❌ | ❌ |
| **Parallel Execution** | ❌ | ✅ | ❌ | ✅ |
| **Maintenance Burden** | Low | High | Low | Medium |
| **Agent Reusability** | ✅ | ❌ | ✅ | ✅ |
| **Structured Output** | ❌ | ✅ | ❌ | ✅ |
| **Setup Complexity** | Low | Medium | Low | High |
| **Best For** | Simple delegation | Task tool features | Team workflows | Multi-command orchestration |

## Key Finding: No Direct Task Tool Workaround Exists

**Critical Gap Identified**:

After extensive research across:
- Official Claude Code documentation
- Community resources (ClaudeLog, Medium, developer blogs)
- GitHub issues and discussions
- Open source agent collections

**Conclusion**: No existing workaround provides all of:
1. ✅ Custom agent definitions from `.claude/agents/`
2. ✅ Tool restriction enforcement via `allowed-tools` frontmatter
3. ✅ Programmatic invocation via Task tool
4. ✅ Structured parameters and error handling

**Why This Matters**:

The Task tool is designed for:
- Parallel task execution
- Structured invocation with timeouts
- Clear task descriptions
- Error handling and recovery

Custom agents provide:
- Specialized expertise and prompts
- Tool access restrictions (security)
- Reusable, modular agent definitions
- Project-specific and user-level customization

**These capabilities are currently mutually exclusive.**

## Technical Analysis

### Task Tool Architecture (Inferred)

```typescript
// Simplified conceptual model based on observed behavior

interface TaskToolInput {
  subagent_type: "general-purpose" | "statusline-setup" | "output-style-setup";
  description: string; // 3-5 words
  prompt: string; // Detailed task instructions
  timeout?: number; // Optional, default 120000ms
}

class TaskTool {
  private registeredAgents = new Map([
    ["general-purpose", GeneralPurposeAgent],
    ["statusline-setup", StatuslineSetupAgent],
    ["output-style-setup", OutputStyleSetupAgent],
  ]);

  async execute(input: TaskToolInput): Promise<TaskResult> {
    const AgentClass = this.registeredAgents.get(input.subagent_type);

    if (!AgentClass) {
      throw new Error(`Agent type '${input.subagent_type}' not found.`);
    }

    const agent = new AgentClass({
      systemPrompt: input.prompt,
      timeout: input.timeout,
      tools: this.inheritToolsFromMainAgent(),
    });

    return await agent.run();
  }

  // ❌ Missing: Dynamic agent registration from .claude/agents/
  // ❌ Missing: Tool restriction enforcement per agent
  // ❌ Missing: Agent frontmatter parsing
}
```

### Proposed Enhancement (Feature #8697)

```typescript
// Enhanced TaskTool with custom agent support

interface CustomAgentDefinition {
  name: string;
  description: string;
  allowedTools?: string[]; // From frontmatter
  systemPrompt: string; // Markdown content
  model?: "sonnet" | "opus" | "haiku";
}

class EnhancedTaskTool extends TaskTool {
  private customAgents = new Map<string, CustomAgentDefinition>();

  constructor() {
    super();
    this.loadCustomAgents();
  }

  private async loadCustomAgents() {
    // 1. Scan .claude/agents/*.md
    const agentFiles = glob(".claude/agents/*.md");

    for (const file of agentFiles) {
      // 2. Parse frontmatter
      const { frontmatter, content } = parseMarkdown(file);

      // 3. Register as valid subagent_type
      this.customAgents.set(frontmatter.name, {
        name: frontmatter.name,
        description: frontmatter.description,
        allowedTools: frontmatter.allowedTools?.split(",").map(t => t.trim()),
        systemPrompt: content,
        model: frontmatter.model,
      });
    }
  }

  async execute(input: TaskToolInput): Promise<TaskResult> {
    // Check custom agents first
    const customAgent = this.customAgents.get(input.subagent_type);

    if (customAgent) {
      const agent = new CustomAgent({
        systemPrompt: `${customAgent.systemPrompt}\n\n${input.prompt}`,
        timeout: input.timeout,
        tools: this.restrictTools(customAgent.allowedTools), // ✅ Enforce tool restrictions
        model: customAgent.model,
      });

      return await agent.run();
    }

    // Fallback to built-in agents
    return super.execute(input);
  }

  private restrictTools(allowedTools?: string[]): ToolSet {
    if (!allowedTools) {
      return this.inheritToolsFromMainAgent(); // No restrictions
    }

    // ✅ Filter tools based on allowed-tools frontmatter
    return this.inheritToolsFromMainAgent().filter(tool =>
      allowedTools.includes(tool.name)
    );
  }
}
```

**Key Enhancements**:
1. ✅ Scan `.claude/agents/*.md` on startup
2. ✅ Parse YAML frontmatter for `allowed-tools`, `description`, `model`
3. ✅ Register custom agents as valid `subagent_type` values
4. ✅ Enforce tool restrictions from frontmatter
5. ✅ Merge agent system prompt with task prompt

## Recommendations

### Immediate Actions (Current Workarounds)

**For Simple Workflows**:
- **Use Workaround 1** (Natural Language Explicit Invocation)
- Minimal setup, works immediately
- Acceptable for non-security-critical tasks

**Example**:
```markdown
# .claude/commands/plan.md

Use the plan-architect agent to create an implementation plan for $ARGUMENTS

The plan should follow project standards in CLAUDE.md and include:
- Multi-phase structure with testing
- Clear success criteria
- File references and line numbers
```

**For Complex Orchestration**:
- **Use Workaround 2** (Embed Instructions) temporarily
- Provides Task tool capabilities (parallel execution, timeouts)
- Plan migration to Workaround 1 once feature #8697 is implemented

**Example**:
```markdown
# .claude/commands/orchestrate.md

# Read agent definitions
1. Read .claude/agents/research-specialist.md
2. Read .claude/agents/plan-architect.md
3. Read .claude/agents/code-writer.md

# Invoke with general-purpose + embedded instructions
Task {
  subagent_type: "general-purpose",
  description: "Research [topic]",
  prompt: "[Embedded research-specialist instructions] + [task details]"
}
```

### Long-Term Strategy

**Monitor Feature Request #8697**:
- Track progress on GitHub
- Participate in discussion if implementation details are debated
- Test beta versions when available

**Prepare for Migration**:
```markdown
# Current (Workaround 1)
Use the plan-architect agent to create plan for $ARGUMENTS

# Future (Feature #8697 implemented)
Task {
  subagent_type: "plan-architect",  # ✅ Will work
  description: "Create implementation plan",
  prompt: "Plan for $ARGUMENTS following CLAUDE.md standards"
}
```

**Document Agent Contracts**:
```markdown
# .claude/agents/plan-architect.md
---
allowed-tools: Read, Write, Grep, Glob, WebSearch
description: Creates structured, phased implementation plans
model: sonnet
---

# Plan Architect Agent

## Tool Usage Contract
- Read: Examine existing code and CLAUDE.md standards
- Write: Create plan files in specs/plans/
- Grep: Search for patterns and references
- Glob: Find related files
- WebSearch: Research best practices (if needed)

## Security Boundaries
- NO file deletion
- NO bash command execution
- NO arbitrary code execution
- READ-ONLY access to existing code
```

### Best Practices for Agent Design

**1. Clear Separation of Concerns**:
```
.claude/agents/
├── plan-architect.md      # Planning specialist
├── research-specialist.md # Research specialist
├── code-writer.md         # Implementation specialist
├── debug-specialist.md    # Debugging specialist
└── doc-writer.md          # Documentation specialist
```

**2. Minimal Tool Access**:
```yaml
# ✅ Good: Minimal necessary tools
allowed-tools: Read, Write, Grep, Glob

# ❌ Bad: Overly permissive
allowed-tools: Read, Write, Bash, Edit, Grep, Glob, WebSearch, WebFetch
```

**3. Explicit Agent Descriptions**:
```yaml
# ✅ Good: Specific, actionable description
description: Creates structured, phased implementation plans following project standards

# ❌ Bad: Vague description
description: Helps with planning stuff
```

**4. Agent Composition Over Duplication**:
```markdown
# .claude/agents/full-stack-architect.md

When planning full-stack features:
1. Use the plan-architect agent for overall structure
2. Use the api-designer agent for backend planning
3. Use the ui-designer agent for frontend planning
4. Synthesize into unified plan
```

## References

### Documentation
- [Claude Code Sub-Agents Documentation](https://docs.claude.com/en/docs/claude-code/sub-agents)
- [Claude Code Slash Commands](https://docs.claude.com/en/docs/claude-code/slash-commands)
- [ClaudeLog - Custom Agents Guide](https://claudelog.com/mechanics/custom-agents/)

### GitHub Issues
- [#8697 - Feature Request: Support custom agents in Task tool](https://github.com/anthropics/claude-code/issues/8697) (OPEN - Created 2025-10-01)
- [#5185 - Custom agents not appearing in /agents interface](https://github.com/anthropics/claude-code/issues/5185) (CLOSED - Fixed in v1.0.84)
- [#4728 - Custom agents not detected by /agents command](https://github.com/anthropics/claude-code/issues/4728) (CLOSED - Fixed in v1.0.84)
- [#4601 - Enable dynamic sub-agent creation via natural language](https://github.com/anthropics/claude-code/issues/4601) (OPEN)

### Community Resources
- [Slash-Commands vs Sub-Agents in Claude Code](https://www.vibesparking.com/en/blog/ai/claude-code/2025-08-03-slash-vs-agents-practical/)
- [Claude Code: Subagent Deep Dive](https://cuong.io/blog/2025/06/24-claude-code-subagent-deep-dive)
- [VoltAgent/awesome-claude-code-subagents](https://github.com/VoltAgent/awesome-claude-code-subagents)
- [wshobson/agents - Production-ready subagents collection](https://github.com/wshobson/agents)

### Local Files
- `.claude/agents/plan-architect.md` - Custom plan architect agent definition
- `.claude/commands/plan.md:165-240` - Agent usage documentation in /plan command
- `.claude/commands/orchestrate.md:410-415` - Agent invocation pattern in /orchestrate command

## Conclusion

The research confirms a genuine architectural gap in Claude Code: custom agents from `.claude/agents/` cannot be used as `subagent_type` values in the Task tool, preventing programmatic invocation with tool restrictions.

**Current State**:
- Custom agents work via natural language explicit invocation
- No tool restriction enforcement
- Limited programmatic control

**Recommended Approach**:
- **Short-term**: Use Workaround 1 (Natural Language Explicit Invocation)
- **Long-term**: Monitor feature request #8697 for Task tool integration

**Impact of Feature #8697**:
- Would enable secure, tool-restricted agent invocation
- Improve workflow orchestration capabilities
- Maintain separation of concerns between agent definitions and command logic
- Support enterprise use cases requiring strict tool access control

This feature would complete Claude Code's agent architecture by bridging the gap between custom agent definitions and programmatic task delegation.

---

*Report generated: 2025-10-01*
*Research conducted by: Claude Code*
*Related GitHub Issue: [#8697](https://github.com/anthropics/claude-code/issues/8697)*
