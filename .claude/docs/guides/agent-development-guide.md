# Agent Development Guide

**Path**: docs → guides → agent-development-guide.md

Comprehensive guide for creating, invoking, and maintaining custom Claude Code agents using the behavioral injection pattern.

**Target Audience**: Developers creating new agent behavioral files, modifying existing agents, or integrating agents into commands.

**Related Documentation**:
- [Command Development Guide](command-development-guide.md) - How commands invoke agents
- [Hierarchical Agent Architecture](../concepts/hierarchical-agents.md) - Overall architecture
- [Troubleshooting Guide](../troubleshooting/agent-delegation-troubleshooting.md) - Common issues

## Quick Start: Your First Agent

**Goal**: Create a simple agent and invoke it from a command in under 10 minutes.

### Step 1: Create Agent File (2 minutes)

Create `.claude/agents/hello-agent.md`:

```markdown
---
allowed-tools: Read, Write
description: Simple demonstration agent that creates greeting files
model: haiku-4.5
model-justification: "Deterministic file creation with template, no complex reasoning required"
---

# Hello Agent

I am a demonstration agent that creates greeting files.

## Core Capabilities
- Create greeting files at specified paths
- Use simple template-based content

## Expected Input
- **Output Path**: Absolute path where greeting file should be created
- **Name**: Name to include in greeting

## Expected Output
- Greeting file created at exact path
- Confirmation message with file path
```

### Step 2: Invoke from Command (3 minutes)

In any command file, invoke the agent:

```markdown
**EXECUTE NOW**: USE the Task tool to invoke hello-agent:

Task {
  subagent_type: "general-purpose"
  description: "Create greeting using hello-agent protocol"
  prompt: |
    Read and follow behavioral guidelines from:
    .claude/agents/hello-agent.md

    Output Path: /tmp/greeting.txt
    Name: Claude
}
```

### Step 3: Verify (1 minute)

Check that `/tmp/greeting.txt` was created with greeting content.

### Next Steps

- **Part 1**: Learn detailed agent file structure and frontmatter fields
- **Part 2**: Master agent invocation patterns (single, parallel, sequential, loop, optional)
- **Part 3**: Understand context architecture for minimizing token usage
- **Part 4**: Advanced patterns (consolidation, refactoring, metrics)

---

## Table of Contents

**Part 1: Creating Agents**
1. [Agent Behavioral Files Overview](#part-1-creating-agents)
2. [The Behavioral Injection Pattern](#12-the-behavioral-injection-pattern)
3. [Agent Files as Single Source of Truth](#13-agent-files-as-single-source-of-truth)
4. [Agent File Structure](#14-agent-file-structure)
5. [Creating a New Agent](#15-creating-a-new-agent)

**Part 2: Invoking Agents**
6. [Agent Invocation Pattern](#part-2-invoking-agents)
7. [Agent Directory](#22-agent-directory)
8. [Integration Patterns](#23-integration-patterns)
9. [Command-Agent Matrix](#24-command-agent-matrix)

**Part 3: Context Architecture**
10. [Layered Context Architecture](#part-3-context-architecture)
11. [Context Preservation Patterns](#32-context-preservation-patterns)
12. [Agent Invocation Best Practices](#33-agent-invocation-best-practices)

**Part 4: Advanced Patterns**
13. [Agent Responsibilities and Boundaries](#part-4-advanced-patterns)
14. [Anti-Patterns and Why They're Wrong](#42-anti-patterns-and-why-theyre-wrong)
15. [Agent Consolidation and Refactoring](#43-agent-consolidation-and-refactoring-patterns)
16. [Testing and Validation](#44-testing-and-validation)
17. [Command-Specific Patterns](#45-command-specific-agent-patterns)
18. [Metrics Integration](#46-metrics-integration)
19. [Troubleshooting](#47-troubleshooting)

---

# Part 1: Creating Agents

---

## 1.1. Agent Behavioral Files Overview

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

## 1.2. The Behavioral Injection Pattern

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

## 1.3. Agent Files as Single Source of Truth

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

## 1.4. Agent File Structure

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

See [Hierarchical Agents Guide](../concepts/hierarchical-agents.md#metadata-extraction) for complete metadata extraction patterns.

---

## 1.5. Creating a New Agent

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

## 1.6. Agent Behavioral/Usage Separation Pattern

### Overview

Similar to the executable/documentation separation pattern for commands (Standard 14), agents benefit from separating lean behavioral files from comprehensive usage guides to maintain clarity and enable independent documentation growth.

### Problem Statement

Agent files mixing behavioral guidelines with extensive usage examples experience similar issues to command files:

**Symptoms**:
- Agent files growing beyond 400 lines with extensive usage documentation
- Behavioral guidelines buried in usage examples and invocation patterns
- Multiple invocation patterns documented inline (>100 lines)
- Difficulty maintaining behavioral guidelines independently from usage examples

**Example**: `research-specialist.md` at 671 lines contains ~200 lines of extractable usage examples, invocation patterns, and integration guidance that could move to a separate usage guide.

### Solution Architecture

**Two-File Pattern** (parallel to command pattern, adjusted for agent complexity):

**1. Agent Behavioral File** (`.claude/agents/agent-name.md`)
- **Purpose**: Lean behavioral guidelines for agent execution
- **Size**: Target <400 lines (agents are more complex than commands, threshold adjusted accordingly)
- **Content**: System prompt, core capabilities, behavioral guidelines, STEP sequences, verification procedures
- **Documentation**: Single-line reference to usage guide
- **Audience**: AI executor (Claude when executing as agent)

**2. Agent Usage Guide** (`.claude/docs/guides/agent-name-agent-guide.md`)
- **Purpose**: Comprehensive usage documentation for command developers
- **Size**: Unlimited (typically 200-1,000 lines)
- **Content**: Invocation patterns, integration examples, parameter guidelines, troubleshooting
- **Cross-reference**: Links back to behavioral file
- **Audience**: Command developers integrating the agent

### When to Split

Consider splitting agent files when:

- **File size** exceeds 400 lines (behavioral + usage documentation combined)
- **Usage examples** are extensive (>100 lines of invocation patterns and integration examples)
- **Multiple invocation patterns** documented (e.g., research with different scopes, plans with different complexity levels)
- **Integration guidance** detailed (>50 lines explaining how to use agent in different contexts)

### Pattern Comparison

| Aspect | Commands | Agents |
|--------|----------|--------|
| **Size Threshold** | 250 lines | 400 lines |
| **Rationale** | Simple execution scripts | More complex behavioral guidelines |
| **Behavioral File** | `.claude/commands/*.md` | `.claude/agents/*.md` |
| **Guide File** | `.claude/docs/guides/*-command-guide.md` | `.claude/docs/guides/*-agent-guide.md` |
| **Content Split** | Bash blocks vs documentation | Behavioral guidelines vs usage |

### Example: Research Specialist

**Current State** (`research-specialist.md`, 671 lines):
- Lines 1-450: Behavioral guidelines (system prompt, capabilities, STEP sequences)
- Lines 451-671: Usage examples (invocation patterns, integration examples, parameter guidelines)

**Proposed Split**:

**`research-specialist.md`** (450 lines):
```markdown
---
allowed-tools: Read, Grep, Write
description: Specialized research agent for comprehensive topic investigation
---

# Research Specialist Agent

**Usage Guide**: See `.claude/docs/guides/research-specialist-agent-guide.md`

## System Prompt

You are a specialized research agent...

## Core Capabilities
[Behavioral guidelines only]

## STEP Sequences
[Execution procedures only]
```

**`research-specialist-agent-guide.md`** (220 lines):
```markdown
# Research Specialist Agent - Usage Guide

**Behavioral File**: `.claude/agents/research-specialist.md`

## Overview
### When to Use This Agent
[Usage guidance]

## Invocation Patterns
### Basic Research
[Example with context injection]

### Complex Multi-Topic Research
[Example with parameters]

## Integration Examples
[How to use in different workflows]

## Troubleshooting
[Common issues and solutions]
```

### Template Requirements

**Note**: Agent templates for this pattern are planned for future work:

- `_template-agent-behavioral.md` (to be created) - Lean behavioral guidelines template
- `_template-agent-usage-guide.md` (to be created) - Comprehensive usage guide template

These templates will follow the same structure as command templates but adjusted for agent-specific needs (higher complexity, behavioral focus).

### Cross-References

**Related Patterns**:
- [Executable/Documentation Separation Pattern](../concepts/patterns/executable-documentation-separation.md) - Parent pattern for commands
- [Command Development Guide - Section 2.4](./command-development-guide.md#24-executabledocumentation-separation-pattern) - Parallel implementation for commands

**Standards**:
- [Standard 14: Executable/Documentation File Separation](../reference/command_architecture_standards.md#standard-14-executabledocumentation-file-separation) - Formal architectural requirement (commands)
- [Standard 12: Structural vs Behavioral Content Separation](../reference/command_architecture_standards.md#standard-12-structural-vs-behavioral-content-separation) - Behavioral content must be in agent files

### Benefits

Applying this pattern to agents provides similar benefits to command separation:

1. **Behavioral Clarity**: Agent behavioral files focused exclusively on execution guidelines
2. **Independent Documentation Growth**: Usage guides can expand without bloating behavioral files
3. **Easier Maintenance**: Behavioral updates don't touch usage docs, usage examples don't risk breaking behavior
4. **Better Discoverability**: Developers can find comprehensive usage guidance without reading behavioral internals

### Migration Checklist

When splitting existing agent files:

1. [ ] Backup original agent file (optional, will be deleted per clean-break)
2. [ ] Identify behavioral sections (system prompt, capabilities, STEP sequences, verification)
3. [ ] Identify usage sections (invocation patterns, integration examples, parameter guides)
4. [ ] Create new lean behavioral file (<400 lines target)
5. [ ] Extract usage documentation to guide file
6. [ ] Add cross-references (bidirectional)
7. [ ] Test agent execution (verify behavioral guidelines still accessible)
8. [ ] Validate usage guide completeness (all invocation patterns documented)
9. [ ] Delete backup (clean-break approach)

### Current Status

**Pattern Status**: Documented (agents not yet migrated)

**Candidate for Migration**:
- `research-specialist.md` (671 lines, ~200 lines extractable)
- Any agent file exceeding 400 lines

**Future Work**:
- Create agent behavioral and usage guide templates
- Migrate research-specialist as proof-of-concept
- Establish validation script for agent pattern compliance

---

# Part 2: Invoking Agents

This part covers how to integrate agents into commands and workflows.

## IMPORTANT: Required Reading for All Command Development

The patterns documented in this part are the ONLY correct patterns for agent invocation. Any command that uses agents MUST follow these patterns.

---

## 2.1. Agent Invocation Pattern

**Available Agent Types** (via Task tool):
- `general-purpose` - General-purpose agent for all specialized behaviors
- `statusline-setup` - Configure statusline settings
- `output-style-setup` - Create output styles

**Specialized Agent Behaviors** (via behavioral injection):
- `research-specialist`, `code-writer`, `test-specialist`, `plan-architect`, `doc-writer`, `code-reviewer`, `debug-specialist`, `metrics-specialist`, `github-specialist`, `complexity_estimator`

**Correct Invocation Pattern**:
```yaml
Task {
  subagent_type: "general-purpose"  # Always use general-purpose
  description: "Create plan using plan-architect protocol"
  prompt: |
    Read and follow the behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/plan-architect.md

    You are acting as a Plan Architect with the constraints and capabilities
    defined in that file.

    [Your actual task description here]
}
```

**Incorrect Pattern** (will cause errors):
```yaml
Task {
  subagent_type: "plan-architect"  # ERROR: Not a valid agent type
  ...
}
```

---

## 2.2. Agent Directory

### Core Agents (Phase 1)

#### 1. research-specialist
- **Purpose**: Read-only research and codebase analysis
- **Tools**: Read, Grep, Glob, WebSearch, WebFetch
- **Use Cases**: Codebase pattern discovery, best practices research, alternative approaches
- **Output**: Concise summaries (max 150-200 words)
- **Invoked By**: /orchestrate (research phase), /plan (optional), /report (optional)

#### 2. code-writer
- **Purpose**: Code generation and modification following project standards
- **Tools**: Read, Write, Edit, Bash, TodoWrite
- **Use Cases**: Implementation, applying fixes, code generation
- **Standards**: Discovers and applies CLAUDE.md standards automatically
- **Invoked By**: /orchestrate (implementation phase), /orchestrate (fix application)

#### 3. test-specialist
- **Purpose**: Test execution and failure analysis
- **Tools**: Bash, Read, Grep
- **Use Cases**: Running tests, analyzing failures, coverage reporting
- **Frameworks**: Multi-framework support (Jest, pytest, Neovim tests, etc.)
- **Invoked By**: /test (optional), /test-all (optional), /orchestrate (validation)

#### 4. plan-architect
- **Purpose**: Phased implementation plan generation
- **Tools**: Read, Write, Grep, Glob, WebSearch
- **Use Cases**: Creating structured plans from research, /implement compatibility
- **Output**: specs/plans/NNN_*.md files
- **Invoked By**: /plan, /orchestrate (planning phase)

### Specialized Agents (Phase 2)

#### 5. doc-writer
- **Purpose**: Documentation creation and maintenance
- **Tools**: Read, Write, Edit, Grep, Glob
- **Use Cases**: README updates, documentation sync, cross-referencing
- **Standards**: Unicode box-drawing, no emojis, CommonMark compliance
- **Invoked By**: /document, /orchestrate (documentation phase)

#### 6. code-reviewer
- **Purpose**: Standards compliance and quality review
- **Tools**: Read, Grep, Glob, Bash
- **Use Cases**: Refactoring analysis, standards enforcement, code quality
- **Output**: Structured reports with severity levels (Blocking/Warning/Suggestion)
- **Invoked By**: /refactor, /orchestrate (optional pre-commit checks)

#### 7. debug-specialist
- **Purpose**: Root cause analysis and diagnostic investigations
- **Tools**: Read, Bash, Grep, Glob, WebSearch
- **Use Cases**: Issue investigation, evidence gathering, solution proposals
- **Output**: Debug reports with multiple solution options
- **Invoked By**: /debug, /orchestrate (debugging loop)

#### 8. metrics-specialist
- **Purpose**: Performance analysis and optimization recommendations
- **Tools**: Read, Bash, Grep
- **Use Cases**: Analyzing metrics from .claude/data/metrics/, identifying bottlenecks
- **Output**: Statistical analysis with optimization suggestions
- **Dependencies**: Requires metrics infrastructure (hooks)
- **Invoked By**: Custom performance analysis commands (future)

#### 9. github-specialist
- **Purpose**: GitHub operations including PRs, issues, and CI/CD monitoring
- **Tools**: Read, Grep, Glob, Bash
- **Use Cases**: PR creation with metadata, issue management, CI workflow monitoring
- **Primary Tool**: gh CLI via Bash (MCP server optional supplement)
- **Output**: PR/issue URLs, CI status reports
- **Invoked By**: /implement (--create-pr), /orchestrate (workflow PRs)

#### 10. complexity_estimator
- **Purpose**: Context-aware complexity analysis for plan expansion/collapse decisions
- **Tools**: Read, Grep, Glob
- **Use Cases**: Auto-analysis mode in /expand and /collapse commands
- **Analysis Factors**: Architectural significance, integration complexity, risk, testing needs
- **Output**: JSON recommendations with 1-10 complexity scores and reasoning
- **Invoked By**: /expand (auto-analysis mode), /collapse (auto-analysis mode)

---

## 2.3. Integration Patterns

### Pattern 1: Single Agent Delegation

Simple command delegates single task to specialized agent using behavioral injection:

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Investigate [issue] using debug-specialist protocol"
  prompt: "
    Read and follow the behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/debug-specialist.md

    You are acting as a Debug Specialist with the tools and constraints
    defined in that file.

    Debug Task: [Detailed investigation instructions]

    Context:
    - Issue description: [from user]
    - Project standards: CLAUDE.md

    Requirements:
    - Gather evidence
    - Identify root cause
    - Propose solutions

    Output: Debug report with findings
  "
}
```

**Used By**: /debug, /document, /refactor

### Pattern 2: Parallel Multi-Agent

Multiple agents of same type work on different topics simultaneously using behavioral injection:

```yaml
# Research Phase in /orchestrate - all in single message for parallel execution
Task {
  subagent_type: "general-purpose"
  description: "Research Topic 1 using research-specialist protocol"
  prompt: |
    Read and follow: /home/benjamin/.config/.claude/agents/research-specialist.md
    You are acting as a Research Specialist.
    [Topic 1 research task]
}
Task {
  subagent_type: "general-purpose"
  description: "Research Topic 2 using research-specialist protocol"
  prompt: |
    Read and follow: /home/benjamin/.config/.claude/agents/research-specialist.md
    You are acting as a Research Specialist.
    [Topic 2 research task]
}
Task {
  subagent_type: "general-purpose"
  description: "Research Topic 3 using research-specialist protocol"
  prompt: |
    Read and follow: /home/benjamin/.config/.claude/agents/research-specialist.md
    You are acting as a Research Specialist.
    [Topic 3 research task]
}
```

**Benefits**: Significant time savings (2-3x faster than sequential)

**Used By**: /orchestrate (research phase)

### Pattern 3: Sequential Pipeline

Output of one agent feeds into next agent in sequence using behavioral injection:

```yaml
# Planning Pipeline
# Step 1: Research using research-specialist behavior
Task {
  subagent_type: "general-purpose"
  prompt: |
    Read and follow: /home/benjamin/.config/.claude/agents/research-specialist.md
    [Research task that generates summary]
}
# Extract research summary from output

# Step 2: Planning using plan-architect behavior
Task {
  subagent_type: "general-purpose"
  prompt: |
    Read and follow: /home/benjamin/.config/.claude/agents/plan-architect.md
    You are acting as a Plan Architect.

    Research findings: [summary from step 1]
    [Planning task]
}
```

**Used By**: /orchestrate (research → planning), /plan (optional research then planning)

### Pattern 4: Conditional Agent Loop

Agent invoked repeatedly until condition met or max iterations using behavioral injection:

```yaml
# Debugging Loop (max 3 iterations)
while tests_failing and iteration < 3:
  # 1. Debug using debug-specialist behavior
  Task {
    subagent_type: "general-purpose"
    prompt: |
      Read and follow: /home/benjamin/.config/.claude/agents/debug-specialist.md
      [Debug task]
  }

  # 2. Fix using code-writer behavior
  Task {
    subagent_type: "general-purpose"
    prompt: |
      Read and follow: /home/benjamin/.config/.claude/agents/code-writer.md
      [Apply fixes]
  }

  # 3. Test using test-specialist behavior
  Task {
    subagent_type: "general-purpose"
    prompt: |
      Read and follow: /home/benjamin/.config/.claude/agents/test-specialist.md
      [Validate fixes]
  }

  if tests_pass:
    break
```

**Used By**: /orchestrate (debugging loop)

### Pattern 5: Optional Agent Enhancement

Command works independently but can delegate to agent for better results using behavioral injection:

```yaml
# Direct execution for simple cases
if simple_task:
  execute_directly()
else:
  # Delegate to agent for complex cases
  Task {
    subagent_type: "general-purpose"
    prompt: |
      Read and follow: /home/benjamin/.config/.claude/agents/test-specialist.md
      [Test execution task]
  }
```

**Used By**: /test, /test-all, /implement (potential)

---

## 2.4. Command-Agent Matrix

| Command | Primary Agent | Secondary Agents | Pattern |
|---------|---------------|------------------|---------|
| /orchestrate | Varies by phase | All 10 agents | Pipeline + Parallel |
| /implement | None (direct) | Potential: code-writer, test-specialist, github-specialist | Direct execution |
| /expand | complexity_estimator (auto-mode) | None | Single delegation |
| /collapse | complexity_estimator (auto-mode) | None | Single delegation |
| /debug | debug-specialist | None | Single delegation |
| /plan | plan-architect | Optional: research-specialist | Sequential pipeline |
| /document | doc-writer | None | Single delegation |
| /refactor | code-reviewer | None | Single delegation |
| /test | test-specialist (optional) | None | Optional enhancement |
| /test-all | test-specialist (optional) | None | Optional enhancement |
| /report | research-specialist (optional) | None | Optional enhancement |

---

# Part 3: Context Architecture

This part explains how to structure agent invocations to minimize context consumption while preserving necessary information.

---

## 3.1. Layered Context Architecture

Agent invocations use a layered context model to separate concerns and minimize context consumption.

**Quick Overview**: For a concise summary of layered context architecture, see [README: Layered Context Architecture](../README.md#layered-context-architecture).

### Five Context Layers

**1. Meta-Context (Behavioral Injection)**:
- Agent behavior definition (read from `.claude/agents/[agent-name].md`)
- Tool restrictions and allowed operations
- Output format requirements
- Passed via: `Read and follow: .claude/agents/[agent-name].md`
- Size: ~0 tokens (agent reads file directly, not passed inline)

**2. Operational Context (Task Instructions)**:
- Specific task description and objectives
- Step-by-step execution requirements
- Success criteria and validation steps
- Passed via: Task `prompt` parameter
- Size: 200-500 tokens typical

**3. Domain Context (Project Standards)**:
- Project-specific coding standards (CLAUDE.md)
- Language conventions and style guides
- Testing protocols and coverage requirements
- Passed via: Reference to CLAUDE.md + key constraints
- Size: 50-100 tokens (reference + highlights, not full content)

**4. Historical Context (Prior Phase Results)**:
- Results from completed workflow phases
- Artifacts created in previous steps
- Key findings and recommendations
- Passed via: Metadata only (path + 50-word summary)
- Size: 250 tokens per artifact (vs 5000 tokens for full content)

**5. Environmental Context (Workflow State)**:
- Current phase in workflow
- Checkpoint data and resume information
- Progress tracking and completion status
- Passed via: Minimal state JSON
- Size: 100-200 tokens

### Practical Example

**Traditional Invocation** (bloated context):
```yaml
Task {
  subagent_type: "general-purpose"
  prompt: |
    You are a Research Specialist. Your role is to analyze codebases and
    gather implementation guidance... [500-word agent definition inline]

    Research Topic: Authentication patterns

    Project Standards: [Full CLAUDE.md content - 5000 tokens]

    Prior Research: [Full report 1 content - 3000 tokens]
                    [Full report 2 content - 2500 tokens]

    Current Workflow State: [Detailed state - 500 tokens]
}
# Total: ~11,500 tokens
```

**Layered Invocation** (optimized):
```yaml
Task {
  subagent_type: "general-purpose"
  description: "Research authentication patterns using research-specialist protocol"
  prompt: |
    # Layer 1: Meta-Context (0 tokens - file read)
    Read and follow: .claude/agents/research-specialist.md

    # Layer 2: Operational Context (300 tokens)
    Research Topic: Authentication patterns in Lua applications

    Requirements:
    - Search codebase for existing auth implementations
    - Research JWT vs sessions best practices
    - Identify security considerations

    Output: Create report at specs/042_auth/reports/001_patterns.md

    # Layer 3: Domain Context (50 tokens)
    Project Standards: CLAUDE.md
    - Lua style: 2-space indent, snake_case
    - Security: HTTPS only, no credentials in code

    # Layer 4: Historical Context (250 tokens)
    Prior Research:
    - specs/041_api/reports/001_rest_patterns.md: "REST API patterns with OpenResty. Recommends JWT for stateless auth."

    # Layer 5: Environmental Context (100 tokens)
    Workflow Phase: research (1/5)
    Thinking Mode: think hard
}
# Total: ~700 tokens (94% reduction)
```

### Benefits

- **Context Reduction**: 90-95% reduction through metadata-only historical context
- **Clarity**: Separation of concerns makes agent invocations easier to debug
- **Reusability**: Meta-context (agent behaviors) shared across invocations
- **Scalability**: Enables 10+ parallel agents without context exhaustion

**See Also**:
- [Command Architecture Standards](../reference/command_architecture_standards.md#layered-context-architecture) for complete layered context guidelines
- [Hierarchical Agents Guide](../concepts/hierarchical-agents.md#metadata-extraction) for metadata extraction patterns

---

## 3.2. Context Preservation Patterns

When integrating agents into multi-phase workflows, use metadata-based context preservation to minimize token consumption. For complete documentation on context preservation patterns, metadata extraction utilities, forward message patterns, and context pruning strategies, see [Hierarchical Agents Guide](../concepts/hierarchical-agents.md).

**Key Patterns** (detailed in hierarchical-agents.md):
- **Metadata-Only Passing**: Extract path + 50-word summary instead of full content (95-99% reduction)
- **Forward Message**: Pass subagent responses without re-summarization (eliminates 200-300 token overhead)
- **Context Pruning**: Prune completed phase data, retain only references (80-90% reduction)

**Target**: <30% context usage throughout multi-phase workflows

**See Also**: [Command Architecture Standards](../reference/command_architecture_standards.md#context-preservation-standards) for Standards 6-8 requirements

---

## 3.3. Agent Invocation Best Practices

### 1. Prompt Construction

**DO**:
- Provide complete task description with objective
- Include necessary context from prior phases (summaries only)
- Reference CLAUDE.md for project standards
- Specify explicit success criteria
- Define expected output format

**DON'T**:
- Include orchestration routing logic
- Pass information about other parallel agents
- Provide excessive context (keep summaries <200 words)
- Use vague instructions without specifics

### 2. Context Management

**Supervisor (Command) Context**: Minimal
- Current workflow state
- High-level summaries only
- File paths (not contents)
- Checkpoint data

**Agent Context**: Comprehensive for their task
- Complete task description
- Relevant prior phase summaries
- Project standards reference
- Explicit requirements

### 3. Error Handling

All agent invocations should handle:
- **Timeout**: Retry with extended timeout or split task
- **Tool Access Errors**: Retry with fallback tools
- **Validation Failures**: Clarify prompt and retry
- **Max Retries**: Escalate to user with context

### 4. Agent Selection

Choose agent based on primary task:
- **Research/Analysis**: research-specialist
- **Code Generation**: code-writer
- **Testing**: test-specialist
- **Planning**: plan-architect
- **Documentation**: doc-writer
- **Code Review**: code-reviewer
- **Debugging**: debug-specialist
- **Performance**: metrics-specialist
- **Complexity Analysis**: complexity_estimator

---

# Part 4: Advanced Patterns

This part covers advanced topics including anti-patterns, consolidation strategies, testing, and troubleshooting.

---

## 4.1. Agent Responsibilities and Boundaries

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

## 4.2. Anti-Patterns and Why They're Wrong

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

## 4.3. Best Practices and Examples

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

## 4.4. Testing and Validation

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

## 4.5. Command-Specific Agent Patterns

### /expand-phase Agent Integration

**Purpose**: Use agents to research complex phases before generating detailed 300-500+ line specifications.

**Agent Selection Logic**:
```bash
# Complexity indicators
if [[ $task_count > 5 ]] || [[ $file_count >= 10 ]] || [[ $unique_dirs > 2 ]]; then
  is_complex=true
  # Select appropriate agent behavior
fi
```

**Invocation Pattern**:

`/expand-phase` uses **general-purpose agents** with **behavioral injection**:

```markdown
Task tool:
  subagent_type: general-purpose  # Only valid agent type
  description: "Research phase context using research-specialist protocol"
  prompt: |
    Read and follow the behavioral guidelines from:
    /path/to/.claude/agents/research-specialist.md

    You are acting as a Research Specialist with constraints:
    - Read-only operations (tools: Read, Glob, Grep only)
    - Concise summaries (200-250 words max)
    - Specific file references with line numbers
    - Evidence-based findings only

    Research Task: [Phase objective]

    Phase Tasks:
    [List all tasks from phase]

    Requirements:
    1. Search codebase for files mentioned in tasks
    2. Identify existing patterns and implementations
    3. Find dependencies and integration points
    4. Assess current state vs target state

    Output Format:
    ## Current State
    - [File:line references]

    ## Patterns Found
    - [Concrete patterns]

    ## Recommendations
    - [Specific approaches]

    ## Challenges
    - [Potential issues]

    Word limit: 250 words
```

**Behavior Selection**:

- **research-specialist**: Default for codebase analysis (most complex phases)
- **code-reviewer**: For refactor/consolidate phases (standards compliance)
- **plan-architect**: For very complex phases (structure recommendations)

**Synthesis Process**:

After agent returns 200-250 word research:

1. Extract key findings (file:line refs, patterns, recommendations, challenges)
2. Map findings to each task in phase
3. Generate code examples based on patterns found
4. Create testing strategy covering current → target transition
5. Write implementation steps using actual file paths discovered

**Output**: 300-500+ line detailed specification with concrete details

**Performance**:
- Simple phases (direct expansion): <2 minutes
- Complex phases (agent-assisted): 3-5 minutes (acceptable for quality gain)

**Benefits**:
- Agent discovers actual file locations and patterns
- Specifications use concrete file:line references
- Testing strategy based on current codebase state
- Implementation steps reference real structures
- Reduces generic placeholder content

---

## 4.6. Metrics Integration

Agents work with hooks for metrics collection:

**post-command-metrics.sh**: Collects agent invocation data
- Operation: agent name
- Duration: execution time
- Status: success/failure

**Metrics Location**: `.claude/data/metrics/YYYY-MM.jsonl`

**Analysis**: Use metrics-specialist to analyze agent performance

---

## 4.7. Troubleshooting

### Agent Not Found

**Symptom**: Task tool reports "unknown subagent type"

**Solutions**:
1. Verify agent file exists in `.claude/agents/`
2. Check frontmatter has `description:` field
3. Ensure filename matches `subagent_type` value

### Agent Access Denied

**Symptom**: Agent reports tool permission errors

**Solutions**:
1. Check `allowed-tools:` in agent frontmatter
2. Verify tool name spelling matches exactly
3. Ensure tool is available in Claude Code

### Agent Timeout

**Symptom**: Agent execution exceeds time limits

**Solutions**:
1. Increase timeout parameter in Task invocation
2. Split task into smaller subtasks
3. Reduce agent workload (less context, focused scope)

### Poor Agent Output

**Symptom**: Agent returns low-quality or incorrect results

**Solutions**:
1. Improve prompt clarity and specificity
2. Provide better context (but keep concise)
3. Add explicit success criteria
4. Show example of expected output format

---

## 4.8. Agent Consolidation and Refactoring

### 4.8.1 When to Consolidate Agents

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

### 4.8.2 Operation Parameter Pattern

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

### 4.8.3 Agent-to-Library Refactoring Pattern

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
   # implementation-executor.md
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

### 4.8.4 Consolidation Impact Metrics

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
- [Testing Patterns](testing-patterns.md) - Validation and quality assurance
- [Standards Integration](standards-integration.md) - CLAUDE.md standards discovery
- [Orchestration Troubleshooting Guide](../guides/orchestration-troubleshooting.md) - Debugging orchestration workflows

### Reference Documentation

- [Hierarchical Agent Architecture](../concepts/hierarchical-agents.md) - Multi-agent coordination
- [Command Architecture Standards](../reference/command_architecture_standards.md) - Architecture standards
- [Agent Reference](../reference/agent-reference.md) - Quick agent reference
- [Troubleshooting Guide](../troubleshooting/agent-delegation-troubleshooting.md) - Common issues

---

**Notes**:
- Follow the Development Philosophy: present-focused documentation, no historical markers
- Use Unicode box-drawing for diagrams, no emojis in content
- Maintain cross-references to related documentation
- Reference utility functions from `.claude/lib/` without duplicating implementations
