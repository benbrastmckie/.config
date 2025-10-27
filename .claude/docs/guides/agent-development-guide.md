# Agent Development Guide

Comprehensive guide for creating and maintaining custom Claude Code agents using the behavioral injection pattern.

**Target Audience**: Developers creating new agent behavioral files or modifying existing ones.

**Related Documentation**:
- [Command Development Guide](command-development-guide.md) - How commands invoke agents
- [Hierarchical Agent Architecture](../concepts/hierarchical_agents.md) - Overall architecture
- [Troubleshooting Guide](../troubleshooting/agent-delegation-issues.md) - Common issues

## Table of Contents

1. [Agent Behavioral Files Overview](#1-agent-behavioral-files-overview)
2. [The Behavioral Injection Pattern](#2-the-behavioral-injection-pattern)
3. [Agent File Structure](#3-agent-file-structure)
4. [Creating a New Agent](#4-creating-a-new-agent)
5. [Agent Responsibilities and Boundaries](#5-agent-responsibilities-and-boundaries)
6. [Anti-Patterns and Why They're Wrong](#6-anti-patterns-and-why-theyre-wrong)
7. [Best Practices and Examples](#7-best-practices-and-examples)
8. [Testing and Validation](#8-testing-and-validation)
9. [Agent Consolidation and Refactoring Patterns](#9-agent-consolidation-and-refactoring-patterns)

---

## 1. Agent Behavioral Files Overview

### What Are Agent Behavioral Files?

Agent behavioral files (`.claude/agents/*.md`) define specialized agent behavior for specific tasks:
- **research-specialist.md**: Conducts codebase research and creates reports
- **plan-architect.md**: Creates implementation plans from requirements
- **code-writer.md**: Executes code changes from task specifications
- **debug-analyst.md**: Investigates bugs and creates debug reports
- **doc-writer.md**: Creates documentation and workflow summaries

### Agent Lifecycle

1. **Command invokes agent**: Primary command uses Task tool to invoke agent
2. **Agent receives context**: Command injects behavioral prompt + task-specific context
3. **Agent executes**: Agent uses Read/Write/Edit tools to complete task
4. **Agent returns metadata**: Path + summary + key findings (NOT full content)
5. **Command processes**: Command verifies artifact and extracts metadata

### Location

- **Project agents**: `.claude/agents/` (takes priority)
- **Global agents**: `~/.config/.claude/agents/` (fallback)

### Naming Convention

- **Filename**: `agent-name.md` (lowercase, hyphens)
- **Agent Name**: Derived from filename without `.md`
- **Display Name**: Formatted in agent file header

Examples:
- `code-writer.md` → agent name: `code-writer`
- `debug-specialist.md` → agent name: `debug-specialist`

---

## 2. The Behavioral Injection Pattern

### Pattern Overview

The behavioral injection pattern separates concerns:
- **Commands**: Orchestration, path calculation, verification, metadata extraction
- **Agents**: Execution, artifact creation, analysis

### How It Works

```
1. Command Pre-Calculates Path
   ↓
   source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-creation.sh"
   TOPIC_DIR=$(get_or_create_topic_dir "$FEATURE" "specs")
   ARTIFACT_PATH=$(create_topic_artifact "$TOPIC_DIR" "reports" "research" "")
   # Result: specs/042_feature/reports/042_research.md

2. Command Loads Agent Behavioral Prompt (Option A)
   ↓
   source "${CLAUDE_PROJECT_DIR}/.claude/lib/agent-loading-utils.sh"
   AGENT_PROMPT=$(load_agent_behavioral_prompt "research-specialist")

   OR Command References Agent File (Option B - Simpler)
   ↓
   (Agent file referenced directly in Task prompt)

3. Command Injects Complete Context
   ↓
   Task {
     subagent_type: "general-purpose"
     prompt: |
       Read and follow: .claude/agents/research-specialist.md

       **Task**: Research authentication patterns
       **Artifact Path**: $ARTIFACT_PATH
       **Success Criteria**: Create report at exact path
   }

4. Agent Creates Artifact
   ↓
   (Agent uses Write tool to create file at ARTIFACT_PATH)

5. Command Verifies and Extracts Metadata
   ↓
   VERIFIED=$(verify_artifact_or_recover "$ARTIFACT_PATH" "research")
   METADATA=$(extract_report_metadata "$VERIFIED")
```

### Why This Pattern?

**Benefits:**
- 📍 **Path Control**: Commands control exact artifact locations
- 📦 **Topic Organization**: All artifacts in topic-based structure
- 🔢 **Consistent Numbering**: Sequential NNN across artifact types
- 🎯 **Context Reduction**: 95% reduction via metadata-only passing
- 🚫 **No Recursion**: Agents never invoke commands that invoked them
- 🏗️ **Architectural Consistency**: All commands follow same pattern

---

## 2.5. Agent Files as Single Source of Truth

### Principle: Agent Behavioral Files Contain ALL Execution Procedures

Agent behavioral files in `.claude/agents/*.md` are the **authoritative source** for all agent execution procedures:

- **Commands reference these files**; they do NOT excerpt or summarize agent guidelines
- **Agent files contain STEP sequences**, PRIMARY OBLIGATION blocks, verification procedures
- **Commands inject context only**: file paths, parameters, requirements

### Benefits of Single Source of Truth

**90% Code Reduction**:
- Before (inline duplication): 150 lines per agent invocation
- After (reference + context): 15 lines per agent invocation
- Result: 90% reduction in command file bloat

**No Synchronization Burden**:
- Before: Update agent guidelines in 5+ command files
- After: Update once in agent file, all commands benefit
- Result: Zero maintenance overhead for agent behavioral changes

**Single Source of Truth**:
- Before: Agent guidelines duplicated across commands (divergence risk)
- After: Agent file is authoritative, commands reference it
- Result: Guaranteed consistency across all invocations

### Example: Behavioral File + Command Reference (Not Duplication)

**Agent File** (`.claude/agents/research-specialist.md` - excerpt):
```markdown
## Behavioral Guidelines

### STEP 1 (REQUIRED BEFORE STEP 2) - Receive and Verify Report Path

**MANDATORY INPUT VERIFICATION**

The invoking command MUST provide you with an absolute report path.
Verify you have received it before proceeding.

### STEP 2 (REQUIRED BEFORE STEP 3) - Conduct Research

**RESEARCH EXECUTION**

Analyze the codebase, documentation, and requirements to address the research topic.

### STEP 3 (REQUIRED BEFORE STEP 4) - Create Report at Exact Path

**PRIMARY OBLIGATION**: File creation is your PRIMARY task.

YOU MUST use the Write tool to create the report file at the exact path
from Step 1 BEFORE populating content.

### STEP 4 (MANDATORY VERIFICATION) - Verify and Return

**ABSOLUTE REQUIREMENT**: Verify file exists before returning.
```

**Command File** (`.claude/commands/report.md` - excerpt):
```markdown
## Phase 2: Invoke Research Agent

**EXECUTE NOW**: Invoke research-specialist with context injection:

Task {
  subagent_type: "general-purpose"
  description: "Research ${TOPIC} with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from: .claude/agents/research-specialist.md

    CONTEXT (inject parameters, not procedures):
    - Research topic: ${TOPIC}
    - Report path: ${REPORT_PATH} (absolute path - verified by command)
    - Focus areas: ${FOCUS_AREAS}
    - Success criteria: Create report at exact path with research findings

    (No STEP sequences here - those are in research-specialist.md)
  "
}
```

### What NOT to Do

**❌ INCORRECT** (Duplicating agent procedures in command):
```markdown
Task {
  prompt: "
    STEP 1: Verify report path...
    STEP 2: Conduct research...
    STEP 3: Create report file at path...
    STEP 4: Verify and return...
    [150+ lines of duplicated agent behavioral guidelines]
  "
}
```

**Why This Is Wrong**:
- Duplicates agent behavioral file content (synchronization burden)
- Violates single source of truth principle
- Adds 90% unnecessary code to command file
- Requires manual updates in multiple places when agent behavior changes

**✓ CORRECT** (Referencing agent file with context injection):
```markdown
Task {
  prompt: "
    Read and follow: .claude/agents/research-specialist.md

    CONTEXT:
    - Report path: ${REPORT_PATH}
    - Research topic: ${TOPIC}
  "
}
```

**Why This Is Right**:
- Agent behavioral file is single source of truth
- Command injects context (parameters) only
- 90% code reduction (150 lines → 15 lines)
- Zero synchronization burden

### Key Takeaway

**Agent files are the ONLY location for behavioral guidelines**. Commands invoke agents via "Read and follow ALL behavioral guidelines from: .claude/agents/[name].md" with context injection. Never duplicate STEP sequences, PRIMARY OBLIGATION blocks, or verification procedures in command prompts.

For detailed guidance, see [Template vs Behavioral Distinction](../reference/template-vs-behavioral-distinction.md).

---

## 3. Agent File Structure

### File Format

```markdown
---
allowed-tools: Tool1, Tool2, Tool3
description: One-line description of agent purpose
---

# Agent Name

System prompt defining agent behavior and capabilities.

## Core Capabilities

[What this agent does]

## Standards Compliance

[Project-specific standards this agent follows]

## Behavioral Guidelines

[How this agent approaches tasks]

## Expected Input

[What information this agent needs to function effectively]

## Expected Output

[What format/structure this agent returns]
```

### Frontmatter Fields

#### allowed-tools (required)

Comma-separated list of tools the agent can use.

```yaml
allowed-tools: Read, Write, Edit, Bash, TodoWrite
```

**Common Tool Combinations**:

| Agent Type | Tools |
|-----------|-------|
| Code Writer | Read, Write, Edit, Bash, TodoWrite |
| Documentation Writer | Read, Write, Edit, Grep, Glob |
| Research | Read, Grep, Glob, WebSearch, WebFetch |
| Testing | Read, Bash, Grep, TodoWrite |
| Debugging | Read, Bash, Grep, Glob, WebSearch |

**Rationale**: These groupings ensure agents have sufficient tools for their task while maintaining security through restriction.

See [Command Architecture Standards](../reference/command_architecture_standards.md#agent-file-standards) for complete tool selection guidelines.

#### description (required)

Brief one-line description of agent's purpose.

```yaml
description: Specialized in writing and modifying code following project standards
```

**Best Practices**:
- Keep under 80 characters
- Focus on primary capability
- Mention key differentiator
- Use active voice

#### model (required)

Specifies which Claude model tier to use for this agent.

```yaml
model: haiku-4.5  # or sonnet-4.5 or opus-4.1
```

**Available Model Tiers**:

| Model | Cost (per 1K tokens) | Use Case |
|-------|---------------------|----------|
| haiku-4.5 | $0.003 | Deterministic tasks, tool orchestration |
| sonnet-4.5 | $0.015 | Complex reasoning, code generation (default) |
| opus-4.1 | $0.075 | Architectural decisions, critical debugging |

**Model Selection Guidelines**:

**Use Haiku when**:
- Task follows explicit rules or templates
- Mechanical operations (file updates, state tracking)
- External tool orchestration (minimal AI reasoning)
- High invocation frequency (cost savings significant)

**Use Sonnet when**:
- Code generation or modification required
- Research synthesis or documentation writing
- Complex reasoning with contextual understanding
- Standard agent tasks (default choice)

**Use Opus when**:
- Architectural design or system-wide decisions
- Critical debugging (high-stakes correctness)
- Multi-hypothesis analysis with deep reasoning
- Low frequency, high-impact operations

See [Model Selection Guide](model-selection-guide.md) for complete decision matrix and migration case studies.

#### model-justification (required)

Explains why this model tier is appropriate for the agent's tasks.

```yaml
model-justification: "Code generation with 30 completion criteria, requires contextual understanding of project standards"
```

**Requirements**:
- Describe task type (deterministic, reasoning, architectural)
- State complexity level (low, medium, high)
- Explain key capability requirements
- Justify model tier selection

**Good Examples**:

```yaml
# Haiku example (deterministic)
model: haiku-4.5
model-justification: "Template-based commit message generation following conventional commit standards, deterministic text formatting"

# Sonnet example (reasoning)
model: sonnet-4.5
model-justification: "Research synthesis across multiple sources with quality analysis, requires understanding of technical concepts and documentation standards"

# Opus example (architectural)
model: opus-4.1
model-justification: "Complex causal reasoning and multi-hypothesis debugging for critical production issues, high-stakes root cause identification with 38 completion criteria"
```

**Poor Examples** (avoid):

```yaml
# Too vague
model-justification: "Complex tasks"

# No complexity assessment
model-justification: "Handles code"

# Missing rationale
model-justification: "Uses Sonnet"
```

#### fallback-model (optional)

Alternative model to use if primary model is unavailable.

```yaml
fallback-model: sonnet-4.5
```

**Best Practices**:
- Typically fallback to Sonnet (balanced capability)
- Only specify if different from default fallback
- Consider compatibility when downgrading from Opus

### System Prompt Structure

#### 1. Introduction

Clear statement of agent identity and purpose.

```markdown
# Code Writer Agent

I am a specialized agent focused on generating and modifying code according to project standards. My role is to implement features, fix bugs, and make code changes while ensuring compliance with established conventions.
```

#### 2. Core Capabilities

Detailed breakdown of what the agent does.

```markdown
## Core Capabilities

### Code Generation
- Write new modules, functions, and classes
- Create configuration files
- Generate boilerplate code following project patterns
- Implement features based on specifications

### Code Modification
- Refactor existing code for clarity or performance
- Fix bugs with targeted changes
- Update code to match new requirements
- Apply standards-compliant formatting
```

**Guidelines**:
- Use hierarchical structure (###, ####)
- List specific capabilities
- Include examples where helpful
- Be concrete, not vague

#### 3. Standards Compliance

Reference to project standards the agent must follow.

```markdown
## Standards Compliance

I follow all guidelines in CLAUDE.md:
- Lua style: 2-space indent, snake_case naming
- Documentation: README.md in every directory
- Error handling: Use pcall for operations that might fail
- Testing: Comprehensive tests for all public APIs
```

**Best Practices**:
- Reference CLAUDE.md explicitly
- List specific standards relevant to agent
- Include language-specific requirements
- Mention testing expectations

#### 4. Behavioral Guidelines

How the agent approaches tasks and makes decisions.

```markdown
## Behavioral Guidelines

### Task Management
- Break complex tasks into phases using TodoWrite
- Mark todos in_progress before starting work
- Complete todos immediately after finishing
- Keep one task in_progress at a time

### Code Quality
- Prefer editing existing files over creating new ones
- Follow DRY principle (Don't Repeat Yourself)
- Write clear, self-documenting code
- Add comments for complex logic only
```

**Guidelines**:
- Describe decision-making process
- Explain priorities and trade-offs
- Include workflow expectations
- Define quality standards

#### 5. Expected Input

What information the agent needs to function effectively.

```markdown
## Expected Input

To function effectively, I need:
- **Task Description**: Clear statement of what to implement
- **Context**: Relevant files, functions, or modules
- **Requirements**: Specific constraints or standards to follow
- **Acceptance Criteria**: How to verify success
```

**Best Practices**:
- Provide clear examples
- Specify required vs optional info
- Include format guidelines
- Show ideal input structure

#### 6. Expected Output

What format/structure the agent returns.

```markdown
## Expected Output

I will deliver:

1. **Code Changes**: Modified or new files following project standards
2. **Tests**: Comprehensive test coverage for new functionality
3. **Documentation**: Updated README files and inline documentation
4. **Summary**: Brief description of changes made

Output format:
```
Completed: [Task description]

Changes:
- Modified: auth.lua (added bcrypt hashing)
- Modified: user.lua (added User model)
- Created: auth_spec.lua (authentication tests)
- Updated: README.md (authentication docs)

Testing: All tests pass (15/15)
```
```

**Guidelines**:
- Specify deliverables clearly
- Include success indicators
- Show output format
- Mention verification steps

### Agent Output Requirements

#### Metadata Extraction Compatibility

When designing agents for multi-agent workflows, ensure outputs are compatible with metadata extraction utilities:

**For Research Agents**:
```markdown
## Executive Summary
[50-word summary of findings - REQUIRED for extract_report_metadata()]

## Key Findings
- [Finding 1 with file:line references]
- [Finding 2 with file:line references]

## Recommendations
1. [Recommendation 1]
2. [Recommendation 2]
```

**For Planning Agents**:
```markdown
## Metadata
- **Complexity**: Low/Medium/High
- **Time Estimate**: N-M hours
- **Phases**: N

## Success Criteria
- [ ] Criterion 1
- [ ] Criterion 2
```

**Why This Matters**: Structured outputs enable `extract_report_metadata()` and `forward_message()` utilities to extract metadata (path + 50-word summary) instead of passing full content between agents, achieving 95% context reduction.

See [Hierarchical Agents Guide](../concepts/hierarchical_agents.md#metadata-extraction) for complete metadata extraction patterns.

---

## 4. Creating a New Agent

### Step 1: Choose Agent Purpose

Identify the specific role and responsibilities.

**Questions to ask**:
- What tasks will this agent handle?
- What makes this agent different from existing agents?
- What specialized knowledge does it need?
- What tools will it require?

### Step 2: Define Agent File

Create `.claude/agents/new-agent.md`:

```markdown
---
allowed-tools: Read, Write, Edit
description: Brief description of agent purpose
---

# New Agent

System prompt content here...
```

### Step 3: Write System Prompt

Follow the structure:
1. Introduction
2. Core Capabilities
3. Standards Compliance
4. Behavioral Guidelines
5. Expected Input
6. Expected Output

**IMPORTANT**: Agent files are the ONLY location for behavioral guidelines:
- Agent files should contain ALL execution procedures (STEP sequences, workflows, verification steps)
- Commands invoke agents via "Read and follow ALL behavioral guidelines from: .claude/agents/[name].md" with context injection
- Never duplicate STEP sequences, PRIMARY OBLIGATION blocks, or verification procedures in command prompts

**Why**: This enables 90% code reduction per agent invocation, single source of truth for agent behavior, and zero synchronization burden.

See [Template vs Behavioral Distinction](../reference/template-vs-behavioral-distinction.md) for detailed guidance on what belongs in agent files vs command files.

### Step 4: Test the Agent

Verify it loads correctly:

```lua
local agent_registry = require('neotex.plugins.ai.claude.agent_registry')

-- Reload to pick up new agent
agent_registry.reload_registry()

-- Verify it exists
local agents = agent_registry.list_agents()
print(vim.inspect(agents))

-- Test loading
local agent = agent_registry.get_agent('new-agent')
if agent then
  print('Agent loaded successfully')
  print('Tools: ' .. table.concat(agent.allowed_tools, ', '))
else
  print('ERROR: Agent failed to load')
end
```

### Step 5: Create Test Task

Test with a simple task to verify behavior:

```lua
local task_config = agent_registry.create_task_config(
  'new-agent',
  'Simple test task',
  'Minimal context for testing'
)

print('Task config: ' .. vim.inspect(task_config))
```

---

## 5. Agent Responsibilities and Boundaries

### Agents SHOULD

✅ **Create artifacts directly using Write tool**
✅ **Use Read/Edit tools to analyze and modify files**
✅ **Use Grep/Glob tools for codebase discovery**
✅ **Return structured metadata (path, summary, findings)**
✅ **Follow topic-based artifact organization**

### Agents SHOULD NOT

❌ **Invoke slash commands** (use SlashCommand tool for artifact creation)
❌ **Make assumptions about artifact paths** (use provided ARTIFACT_PATH)
❌ **Return full artifact content** (metadata only)
❌ **Create artifacts outside topic-based structure**

### Tool Usage Guidelines

#### Allowed Tools (for Agents)

**File Operations**:
- **Read**: Read file contents for analysis
- **Write**: Create new files at provided paths
- **Edit**: Modify existing files with exact string replacement

**Code Discovery**:
- **Grep**: Search file contents with regex patterns
- **Glob**: Find files matching glob patterns
- **WebSearch**: Research external documentation (when needed)

**Execution**:
- **Bash**: Run commands for testing, validation, file operations

#### Restricted Tools (for Agents)

**SlashCommand Tool**:
- **NEVER** use SlashCommand for:
  - `/plan` - Plan creation is command's responsibility
  - `/report` - Report creation is direct (not via command)
  - `/implement` - Implementation orchestration is command's responsibility
  - `/debug` - Debug workflow is command's responsibility

**Exceptions** (when SlashCommand IS allowed):
- Agent needs to delegate to another specialized command (rare)
- Explicitly instructed in behavioral file (with clear rationale)
- Example: doc-writer invoking `/list reports` to discover artifacts

### Tool Selection Decision Tree

```
Need to create artifact?
  ↓
  Is ARTIFACT_PATH provided in context?
    ↓ YES
    Use Write tool with exact path ✅
    ↓ NO
    ERROR: Agent should not assume paths ❌

Need to modify existing file?
  ↓
  Use Edit tool with old_string/new_string ✅

Need to search codebase?
  ↓
  Content search → Grep ✅
  File search → Glob ✅

Need to execute command?
  ↓
  File operation (cp, mv, mkdir) → Bash ✅
  Slash command (/plan, /implement) → NEVER ❌
```

---

## 6. Anti-Patterns and Why They're Wrong

### Anti-Pattern 1: Agent Invokes Slash Command

**WRONG:**
```markdown
# plan-architect.md

## Step 1: Create Implementation Plan

**CRITICAL**: You MUST use the SlashCommand tool to invoke /plan:

SlashCommand {
  command: "/plan ${FEATURE_DESCRIPTION}"
}
```

**Why It's Wrong:**
- ❌ Loss of path control (can't pre-calculate artifact location)
- ❌ Cannot extract metadata before context bloat
- ❌ Breaks topic-based organization (slash command may use different structure)
- ❌ Violates separation of concerns (agent doing orchestration)
- ❌ Makes testing difficult (can't mock agent behavior)

**Impact:**
- Context bloat: 168.9k tokens (no reduction)
- Artifacts may be created in wrong locations
- Inconsistent numbering across workflows

### Anti-Pattern 2: Agent Invokes Command That Invoked It

**WRONG:**
```markdown
# code-writer.md

## Type A: Plan-Based Implementation

If you receive a plan file path, use /implement to execute it:

SlashCommand {
  command: "/implement ${PLAN_PATH}"
}
```

**Why It's Wrong:**
- ❌ **Recursion risk**: /implement → code-writer → /implement → ∞
- ❌ Infinite loops possible
- ❌ Agent misunderstanding its role (executor, not orchestrator)

**Impact:**
- Risk of infinite recursion
- Timeouts and failures
- Confused responsibility boundaries

### Anti-Pattern 3: Manual Path Construction

**WRONG:**
```markdown
# research-specialist.md

Create report at: specs/reports/${TOPIC}.md
```

**Why It's Wrong:**
- ❌ Breaks topic-based organization (flat structure)
- ❌ Inconsistent numbering (no NNN prefix)
- ❌ Difficult artifact discovery (scattered locations)
- ❌ Non-compliant with directory protocols

**Impact:**
- Reports created in flat structure: `specs/reports/topic.md`
- Should be: `specs/042_topic/reports/042_topic.md`
- Loss of centralized artifact organization

---

## 7. Best Practices and Examples

### DO

- **Be Specific**: Define clear, focused capabilities
- **Reference Standards**: Explicitly mention CLAUDE.md
- **Provide Examples**: Show expected input/output formats
- **Use Active Voice**: "I implement features" not "Features are implemented"
- **Test Thoroughly**: Verify agent loads and behaves correctly
- **Version Control**: Track agent changes in git
- **Document Updates**: Note when and why agent changed

### DON'T

- **Be Vague**: Avoid general statements like "I do things well"
- **Duplicate Existing Agents**: Check if capability exists first
- **Over-Promise**: Only list tools you actually need
- **Ignore Standards**: Always reference project conventions
- **Skip Testing**: Always verify agent loads correctly
- **Use Emojis**: Keep to UTF-8 text, no emoji characters

### Common Patterns

#### Specialized Code Agent

Focus on specific language or framework:

```markdown
---
allowed-tools: Read, Write, Edit, Bash, Grep
description: Specialized in React TypeScript development
---

# React TypeScript Specialist

I am an expert in React and TypeScript, focused on building modern web applications following best practices.

## Core Capabilities
- Component development with hooks
- State management (Context, Redux, Zustand)
- Type-safe props and interfaces
- Performance optimization
- Accessibility (WCAG 2.1)
```

#### Documentation Agent

Focus on writing and maintaining docs:

```markdown
---
allowed-tools: Read, Write, Edit, Grep, Glob
description: Maintains comprehensive project documentation
---

# Documentation Writer

I specialize in creating and maintaining clear, consistent documentation for software projects.

## Core Capabilities
- README files for all directories
- API documentation
- User guides and tutorials
- Architecture diagrams (Unicode box-drawing)
- Changelog maintenance
```

#### Analysis Agent

Focus on investigation without modification:

```markdown
---
allowed-tools: Read, Grep, Glob, WebSearch, WebFetch
description: Analyzes codebases and provides insights
---

# Code Analyst

I conduct thorough analysis of codebases without making modifications, providing insights and recommendations.

## Core Capabilities
- Architecture analysis
- Dependency mapping
- Performance profiling
- Security auditing
- Best practice recommendations
```

### Reference Implementation Examples

#### Pattern 1: Agent Creates Artifact at Provided Path

**CORRECT:**
```markdown
# plan-architect.md

## Step 1: Receive Task Context

You will receive:
- **Feature Description**: The feature to implement
- **Research Reports**: Paths to research that informs the plan
- **Plan Output Path**: EXACT path where plan must be created

## Step 2: Create Implementation Plan

Use the Write tool to create the plan at the EXACT path provided:

Write {
  file_path: "${PLAN_PATH}"  # Use exact path from context
  content: |
    # ${FEATURE} Implementation Plan

    ## Metadata
    - **Research Reports**: (paths provided in context)

    ## Phases
    ...
}

## Step 3: Return Metadata

Return structured metadata:
{
  "path": "${PLAN_PATH}",
  "phase_count": N,
  "complexity_score": XX,
  "estimated_hours": YY
}
```

**Why It's Correct:**
- ✅ Agent uses provided path (no assumptions)
- ✅ Uses Write tool (not SlashCommand)
- ✅ Returns metadata only (no full content)
- ✅ Clear separation of concerns

#### Pattern 2: Research Agent with Topic-Based Artifacts

**CORRECT:**
```markdown
# research-specialist.md

## Step 1: Receive Research Context

You will receive:
- **Research Focus**: Topic to research (patterns, best practices, alternatives)
- **Feature Description**: Context for research
- **Report Output Path**: EXACT topic-based path (specs/{NNN_topic}/reports/{NNN}_topic.md)

## Step 2: Conduct Research

Use Grep, Glob, Read tools to:
1. Search codebase for existing implementations
2. Identify relevant patterns and utilities
3. Research best practices
4. Document alternative approaches

## Step 3: Create Report at Exact Path

Write {
  file_path: "${REPORT_PATH}"  # Topic-based path from context
  content: |
    # ${TOPIC} Research Report

    ## Executive Summary
    (50-word summary)

    ## Findings
    ...

    ## Recommendations
    ...
}

## Step 4: Return Metadata

{
  "path": "${REPORT_PATH}",
  "summary": "50-word summary",
  "key_findings": ["finding 1", "finding 2"],
  "recommendations": ["rec 1", "rec 2"]
}
```

**Why It's Correct:**
- ✅ Uses provided topic-based path
- ✅ Metadata-only return (95% context reduction)
- ✅ Clear research methodology
- ✅ Structured output format

---

## 8. Testing and Validation

### Agent Loading Tests

Verify agent loads correctly:

```lua
local agent = agent_registry.get_agent('my-agent')
if not agent then
  print('ERROR: Agent failed to load')
  return
end

print('Agent loaded: ' .. agent.name)
print('Tools: ' .. table.concat(agent.allowed_tools, ', '))
print('Description: ' .. agent.description)
```

### Manual Testing Procedure

1. Create test agent file
2. Reload agent registry
3. Verify agent appears in list
4. Create task config
5. Test agent invocation
6. Verify expected output

### Quality Checklist

Before committing a new agent:

**Structure**:
- [ ] Frontmatter metadata complete
- [ ] allowed-tools appropriate
- [ ] description clear and concise
- [ ] All sections present

**Content**:
- [ ] Clear purpose statement
- [ ] Core capabilities detailed
- [ ] Standards compliance documented
- [ ] Behavioral guidelines specific
- [ ] Expected input/output formats defined

**Behavior**:
- [ ] Uses Write/Edit tools (not SlashCommand)
- [ ] Accepts provided ARTIFACT_PATH
- [ ] Returns metadata only
- [ ] Follows topic-based organization

**Testing**:
- [ ] Agent loads successfully
- [ ] Test task completes
- [ ] Metadata returned correctly
- [ ] Artifact created at expected path

---

## Cross-References

## 9. Agent Consolidation and Refactoring Patterns

### 9.1 When to Consolidate Agents

Consider consolidating agents when:

1. **High Code Overlap** (>90%):
   - Similar STEP-by-STEP workflows
   - Nearly identical validation logic
   - Shared metadata update patterns

   **Example**: expansion-specialist + collapse-specialist (95% overlap) → plan-structure-manager

2. **Pure Coordination Wrappers**:
   - No behavioral logic
   - Only delegates to another agent
   - No value-add processing

   **Example**: plan-expander (only delegated to expansion-specialist) → Archived

3. **Deterministic Logic**:
   - No AI reasoning required
   - Purely algorithmic transformations
   - Can be implemented as library function

   **Example**: git-commit-helper (purely deterministic) → .claude/lib/git-commit-utils.sh

### 9.2 Operation Parameter Pattern

When consolidating similar agents into a unified agent, use operation parameters to dispatch behavior:

**Pattern**:
```yaml
# Agent frontmatter
description: Unified agent for expanding/collapsing phases and stages in implementation plans

# Invocation from command
Task {
  subagent_type: "general-purpose"
  description: "Expand phase 2"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-structure-manager.md

    Operation: expand  # or "collapse"

    Plan Path: /path/to/plan.md
    Phase Number: 2
}
```

**Benefits**:
- Single agent file vs multiple similar files
- Shared validation, error handling, artifact creation logic
- Clearer architectural pattern (operation parameter = behavior selector)

**Implementation**:
```markdown
## Behavioral Guidelines

### Operation Modes

**STEP 1: Validate Operation Request**
- Check operation parameter: "expand" | "collapse"
- Validate inputs based on operation type

**STEP 2: Execute Operation**
- IF operation = "expand": Extract content to separate file
- IF operation = "collapse": Merge content back into parent plan

**STEP 3: Update Parent Plan**
- IF operation = "expand": Add marker + summary
- IF operation = "collapse": Replace marker with inline content
```

### 9.3 Agent-to-Library Refactoring Pattern

When agent logic is purely deterministic, refactor to utility library:

**Decision Criteria**:
- No AI reasoning required?
- Purely algorithmic transformations?
- Fixed input → fixed output mapping?
- No context-dependent decisions?

**Refactoring Process**:

1. **Identify Deterministic Logic**:
   ```markdown
   # git-commit-helper.md (BEFORE)
   Generate commit message:
   - Stage completion: "feat(NNN): complete Phase N Stage M - Name"
   - Phase completion: "feat(NNN): complete Phase N - Name"
   - Plan completion: "feat(NNN): complete Feature Name"
   ```

2. **Extract to Library Function**:
   ```bash
   # .claude/lib/git-commit-utils.sh (AFTER)
   generate_commit_message() {
     local topic_number="$1"
     local completion_type="$2"  # phase|stage|plan
     local phase_number="$3"
     local stage_number="$4"
     local name="$5"
     local feature_name="$6"

     case "$completion_type" in
       stage)
         echo "feat($topic_number): complete Phase $phase_number Stage $stage_number - $name"
         ;;
       phase)
         echo "feat($topic_number): complete Phase $phase_number - $name"
         ;;
       plan)
         echo "feat($topic_number): complete $feature_name"
         ;;
     esac
   }
   ```

3. **Update Callers**:
   ```markdown
   # implementation-executor.md (UPDATED)
   ## Create Git Commit

   **STEP 1: Generate Commit Message Using git-commit-utils.sh**

   ```bash
   # Load git-commit-utils.sh library
   source "${CLAUDE_PROJECT_DIR}/.claude/lib/git-commit-utils.sh"

   # Generate commit message using library function
   commit_msg=$(generate_commit_message "$topic_num" "phase" "$phase_number" "" "$phase_name" "")
   ```

4. **Archive Agent**:
   ```bash
   mv .claude/agents/git-commit-helper.md .claude/archive/agents/
   ```

**Benefits**:
- Zero agent invocation overhead
- Faster execution (library function vs agent Task)
- Easier testing (unit tests vs integration tests)
- Clearer separation of concerns (algorithms in lib/, AI reasoning in agents/)

### 9.4 Consolidation Impact Metrics

Track consolidation benefits:

**Code Reduction**:
- Lines saved: Old agents total - New unified agent
- Example: expansion-specialist (25KB) + collapse-specialist (21KB) = 46KB → plan-structure-manager (36KB) = 10KB saved (21% reduction)

**Performance**:
- Agent invocation overhead eliminated (agent-to-library refactoring)
- Example: git-commit-helper (agent Task ~500ms) → library function (~5ms) = 99% faster

**Maintainability**:
- Agents to maintain: Old count - Archived count
- Example: 22 agents → 19 agents = 14% reduction

---

### Architectural Patterns

Agents should implement these patterns from the [Patterns Catalog](../concepts/patterns/README.md):

- [Behavioral Injection](../concepts/patterns/behavioral-injection.md) - How agents receive context from commands
- [Metadata Extraction](../concepts/patterns/metadata-extraction.md) - Returning summaries instead of full content
- [Forward Message Pattern](../concepts/patterns/forward-message.md) - Passing subagent responses directly
- [Hierarchical Supervision](../concepts/patterns/hierarchical-supervision.md) - Coordinating sub-agents recursively
- [Context Management](../concepts/patterns/context-management.md) - Minimizing token usage in outputs

### Related Guides

- [Command Development Guide](command-development-guide.md) - How commands invoke agents
- [Using Agents](using-agents.md) - Agent invocation and coordination patterns
- [Testing Patterns](testing-patterns.md) - Validation and quality assurance
- [Standards Integration](standards-integration.md) - CLAUDE.md standards discovery

### Reference Documentation

- [Hierarchical Agent Architecture](../concepts/hierarchical_agents.md) - Multi-agent coordination
- [Command Architecture Standards](../reference/command_architecture_standards.md) - Architecture standards
- [Agent Reference](../reference/agent-reference.md) - Quick agent reference
- [Troubleshooting Guide](../troubleshooting/agent-delegation-issues.md) - Common issues

---

**Notes**:
- Follow the Development Philosophy: present-focused documentation, no historical markers
- Use Unicode box-drawing for diagrams, no emojis in content
- Maintain cross-references to related documentation
- Reference utility functions from `.claude/lib/` without duplicating implementations
