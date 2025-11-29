# Agents Directory

Specialized AI agent definitions for Claude Code. Each agent is a focused assistant with specific capabilities, tool access, and expertise designed to handle particular aspects of development workflows.

**Current Agent Count**: 16 active agents

## Purpose

Agents enable modular, focused assistance by providing:

- **Specialized capabilities** for specific task types
- **Restricted tool access** for safety and predictability
- **Consistent behavior** across invocations
- **Reusable expertise** that can be invoked by commands

## Agent Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ Command (/implement, /plan, /test, etc.)                   │
│ Orchestrates workflow and task delegation                  │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ Agent Invocation                                            │
│ Loads agent definition and context                         │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ Specialized Agent                                           │
├─────────────────────────────────────────────────────────────┤
│ • Focused instruction set                                   │
│ • Limited tool access                                       │
│ • Domain-specific expertise                                 │
│ • Task completion and reporting                             │
└─────────────────────────────────────────────────────────────┘
```

## Available Agents

### Command-to-Agent Mapping

Quick reference for which agents are invoked by each command and their roles:

#### /plan
- **workflow-classifier** - Classify request type (feature, bugfix, research)
- **plan-complexity-classifier** - Assess feature complexity for planning depth
- **research-specialist** - Gather codebase context and best practices
- **plan-architect** - Design implementation plan with phases and tasks

#### /repair
- **repair-analyst** - Analyze error logs and identify root cause patterns
- **plan-architect** - Create fix implementation plan based on error analysis

#### /research
- **research-specialist** - Conduct technology investigation and generate reports

#### /revise
- **research-specialist** - Research updates needed for plan revision
- **plan-architect** - Integrate changes into revised plan

#### /build
- **implementer-coordinator** - Orchestrate wave-based parallel phase execution
- **implementation-executor** - Execute individual phase tasks
- **spec-updater** - Track progress via checkbox updates
- **debug-analyst** - Investigate build failures

#### /debug
- **workflow-classifier** - Classify issue type
- **research-specialist** - Analyze codebase for issue context
- **plan-architect** - Design fix plan if needed
- **debug-analyst** - Test hypotheses in parallel
- **debug-specialist** - Perform root cause analysis

#### /expand
- **complexity-estimator** - Assess complexity for expansion decisions

#### /collapse
- **complexity-estimator** - Assess complexity for collapse decisions

#### /setup
- **claude-md-analyzer** - Analyze CLAUDE.md structure
- **docs-structure-analyzer** - Audit documentation organization
- **docs-bloat-analyzer** - Detect semantic redundancy
- **docs-accuracy-analyzer** - Verify documentation accuracy
- **cleanup-plan-architect** - Create optimization plans

#### /convert-docs
- **doc-converter** - Convert Word/PDF documents to Markdown

#### /todo
- **todo-analyzer** - Classify plan status for TODO.md organization

### Model Selection Patterns

Agents use different models based on task requirements:

#### haiku / haiku-4.5
Fast classification, deterministic operations, parsing:
- **plan-complexity-classifier** - Rapid complexity assessment
- **complexity-estimator** - Fast complexity scoring for expand/collapse
- **implementer-coordinator** - Deterministic wave coordination
- **spec-updater** - Consistent checkbox and progress updates
- **doc-converter** - Reliable format conversion operations
- **claude-md-analyzer** - Fast structural analysis
- **docs-structure-analyzer** - Rapid documentation scanning
- **todo-analyzer** - Fast plan status classification for batch processing

#### sonnet-4.5
Complex reasoning, research, coordination:
- **research-specialist** - Deep codebase analysis and report generation
- **implementation-executor** - Complex code generation and testing
- **research-sub-supervisor** - Multi-worker coordination
- **debug-analyst** - Parallel hypothesis testing
- **cleanup-plan-architect** - Planning reasoning for cleanup tasks

#### opus-4.1 / opus-4.5
Architectural decisions, complex debugging, semantic analysis:
- **plan-architect** - High-quality architectural design decisions
- **debug-specialist** - Deep root cause analysis
- **docs-bloat-analyzer** - Semantic redundancy detection
- **docs-accuracy-analyzer** - Code-documentation consistency verification

---

### debug-specialist.md
**Purpose**: Investigate and diagnose issues without making changes
**Model**: opus-4.1 (complex root cause analysis)

**Used By Commands**: /debug

**Capabilities**:
- Error analysis
- Log inspection
- Environment investigation
- Root cause analysis
- Diagnostic report generation
- File-based debug reports for orchestrated workflows
- Persistent debugging documentation in `debug/{topic}/`

**Dependencies**: None

**Allowed Tools**: Read, Grep, Glob, Bash, WebSearch, Write

**Typical Use Cases**:
- Troubleshooting failures
- Understanding error messages
- Investigating performance issues
- Creating debug reports during debugging loops

---

### doc-converter.md
**Purpose**: Convert Word (DOCX) and PDF files to Markdown format
**Model**: haiku-4.5 (deterministic conversion operations)

**Used By Commands**: /convert-docs

**Capabilities**:
- Batch document conversion (DOCX and PDF)
- MarkItDown-based DOCX and PDF conversion (primary tool)
- Pandoc-based DOCX conversion fallback
- PyMuPDF4LLM PDF conversion backup (fast, lightweight)
- Image extraction and organization
- Conversion validation and quality checks
- Progress reporting and statistics

**Dependencies**:
- External tools: markitdown, pandoc, pymupdf4llm

**Allowed Tools**: Read, Grep, Glob, Bash, Write

**Typical Use Cases**:
- Converting legacy documentation to Markdown
- Batch processing document archives
- Migrating Word docs to version control
- Extracting content from PDF reports

---

### plan-architect.md
**Purpose**: Design implementation plans from requirements
**Model**: opus-4.1 (architectural decisions)

**Used By Commands**: /plan, /revise, /debug

**Capabilities**:
- Requirements analysis
- Architecture design
- Phase breakdown
- Risk assessment
- Success criteria definition
- Report verification and linking in plan metadata
- Cross-referencing research reports

**Dependencies**: None (self-contained)

**Allowed Tools**: Read, Write, Grep, Glob

**Typical Use Cases**:
- Creating implementation plans
- Designing feature architecture
- Breaking down complex tasks

---

### research-specialist.md
**Purpose**: Conduct research and generate comprehensive reports
**Model**: sonnet-4.5 (complex reasoning and research)

**Used By Commands**: /plan, /research, /revise, /debug

**Capabilities**:
- Technology investigation
- Best practices research
- Feasibility analysis
- Alternative comparison
- Report writing
- Direct report file creation in `specs/reports/{topic}/`
- Topic-based organization with incremental numbering
- Integration with research phases in workflows

**Dependencies**:
- Libraries: `.claude/lib/core/unified-location-detection.sh`

**Allowed Tools**: Read, Write, Grep, Glob, WebSearch

**Typical Use Cases**:
- Technology evaluation
- Problem investigation
- Pre-implementation research
- Research phase execution in orchestrated workflows

---

### complexity-estimator.md
**Purpose**: Provide context-aware complexity analysis for plan expansion/collapse decisions
**Model**: haiku-4.5 (fast complexity assessment)

**Used By Commands**: /expand, /collapse

**Capabilities**:
- Context-aware complexity estimation (1-10 scale)
- Architectural significance assessment
- Integration complexity analysis
- Risk and testing requirements evaluation
- JSON-structured recommendations with reasoning

**Dependencies**: None (read-only)

**Allowed Tools**: Read, Grep, Glob

**Typical Use Cases**:
- Auto-analysis mode in /expand command
- Auto-analysis mode in /collapse command
- Determining which phases warrant separate files
- Evaluating if expanded content can be collapsed

---

### debug-analyst.md
**Purpose**: Parallel hypothesis testing for debugging
**Model**: sonnet-4.5 (complex analysis)

**Used By Commands**: /debug, /build

**Capabilities**:
- Hypothesis generation and testing
- Parallel failure analysis
- Root cause identification
- Solution recommendation

**Dependencies**: None

**Allowed Tools**: Read, Grep, Glob, Bash

**Typical Use Cases**:
- Testing multiple debug hypotheses in parallel
- Build failure investigation
- Implementation error diagnosis

---

### implementer-coordinator.md
**Purpose**: Wave-based parallel phase execution orchestration
**Model**: haiku-4.5 (deterministic coordination)

**Used By Commands**: /build

**Capabilities**:
- Dependency analysis and wave structure building
- Parallel executor invocation
- Progress monitoring and aggregation
- Failure handling and isolation

**Dependencies**: None (self-contained)

**Allowed Tools**: Read, Bash, Task

**Subagents Invoked**: implementation-executor

**Typical Use Cases**:
- Orchestrating multi-phase implementations
- Maximizing parallel execution (40-60% time savings)
- Build workflow coordination

---

### implementation-executor.md
**Purpose**: Execute single phase implementation tasks
**Model**: sonnet-4.5 (complex implementation reasoning)

**Used By Commands**: /build (via implementer-coordinator)

**Capabilities**:
- Phase task execution
- Progress tracking and plan updates
- Test running and validation
- Git commit creation

**Dependencies**: None

**Allowed Tools**: Read, Write, Edit, Bash, Grep, Glob, Task

**Subagents Invoked**: spec-updater

**Typical Use Cases**:
- Executing individual plan phases
- Single-phase implementation with testing
- Code generation and validation

---

### spec-updater.md
**Purpose**: Manage artifact updates and progress tracking
**Model**: haiku-4.5 (deterministic updates)

**Used By Commands**: /build

**Capabilities**:
- Checkbox state management
- Plan file progress updates
- Artifact synchronization
- Status marker placement

**Dependencies**:
- Libraries: `.claude/lib/plan/checkbox-utils.sh`

**Allowed Tools**: Read, Write, Edit, Bash

**Typical Use Cases**:
- Marking tasks complete in plan files
- Synchronizing progress across artifacts
- Maintaining plan file consistency

---

### claude-md-analyzer.md
**Purpose**: Analyze CLAUDE.md structure and content
**Model**: haiku-4.5 (fast structural analysis)

**Used By Commands**: /setup

**Capabilities**:
- CLAUDE.md structure analysis
- Section identification
- Content organization assessment
- Optimization recommendations

**Dependencies**:
- Libraries: `.claude/lib/core/unified-location-detection.sh`, `.claude/lib/util/optimize-claude-md.sh`

**Allowed Tools**: Read, Grep, Glob, Bash

**Typical Use Cases**:
- Analyzing existing CLAUDE.md for improvements
- Structure validation
- Content optimization planning

---

### docs-structure-analyzer.md
**Purpose**: Analyze documentation directory organization
**Model**: haiku-4.5 (fast structural analysis)

**Used By Commands**: /setup

**Capabilities**:
- Documentation structure mapping
- Navigation link validation
- Organization quality assessment
- Reorganization recommendations

**Dependencies**:
- Libraries: `.claude/lib/core/unified-location-detection.sh`

**Allowed Tools**: Read, Grep, Glob, Bash

**Typical Use Cases**:
- Auditing documentation directory structure
- Finding broken navigation links
- Planning documentation reorganization

---

### docs-bloat-analyzer.md
**Purpose**: Semantic bloat detection in documentation
**Model**: opus-4.5 (high-quality semantic analysis)

**Used By Commands**: /setup

**Capabilities**:
- Duplicate content detection
- Semantic redundancy identification
- Content consolidation recommendations
- Bloat severity scoring

**Dependencies**:
- Libraries: `.claude/lib/core/unified-location-detection.sh`

**Allowed Tools**: Read, Grep, Glob, Bash

**Typical Use Cases**:
- Finding duplicate documentation
- Reducing documentation bloat
- Consolidating overlapping content

---

### docs-accuracy-analyzer.md
**Purpose**: Documentation accuracy and consistency verification
**Model**: opus-4.5 (high-quality analysis)

**Used By Commands**: /setup

**Capabilities**:
- Code-documentation consistency checking
- Accuracy verification
- Outdated content detection
- Update recommendations

**Dependencies**:
- Libraries: `.claude/lib/core/unified-location-detection.sh`

**Allowed Tools**: Read, Grep, Glob, Bash

**Typical Use Cases**:
- Verifying documentation accuracy
- Finding outdated documentation
- Ensuring code-doc consistency

---

### cleanup-plan-architect.md
**Purpose**: Create optimization plans for CLAUDE.md cleanup
**Model**: sonnet-4.5 (planning reasoning)

**Used By Commands**: /setup

**Capabilities**:
- Cleanup plan generation
- Priority assessment
- Implementation phase design
- Risk evaluation

**Dependencies**:
- Libraries: `.claude/lib/core/unified-location-detection.sh`

**Allowed Tools**: Read, Write, Grep, Glob

**Typical Use Cases**:
- Creating CLAUDE.md optimization plans
- Prioritizing cleanup tasks
- Designing cleanup implementation

---

### plan-complexity-classifier.md
**Purpose**: Classify feature complexity for planning
**Model**: haiku (fast classification)

**Used By Commands**: /plan

**Capabilities**:
- Feature complexity assessment
- Planning depth recommendation
- Resource estimation
- Risk classification

**Dependencies**:
- Libraries: `.claude/lib/core/state-persistence.sh`

**Allowed Tools**: None

**Typical Use Cases**:
- Determining planning depth requirements
- Classifying feature complexity level
- Resource allocation guidance

---

### todo-analyzer.md
**Purpose**: Fast plan status classification for TODO.md organization
**Model**: haiku-4.5 (fast batch processing)

**Used By Commands**: /todo

**Capabilities**:
- Plan metadata extraction (title, status, description)
- Status field classification (COMPLETE, IN PROGRESS, NOT STARTED, etc.)
- Phase completion counting (fallback when status missing)
- Structured JSON output for batch processing

**Dependencies**: None (read-only)

**Allowed Tools**: Read

**Typical Use Cases**:
- Batch classification of 100+ plans for TODO.md updates
- Determining plan status from metadata or phase markers
- Providing structured data for TODO.md section organization

## Agent Definition Format

Each agent is defined in a markdown file with frontmatter metadata:

```markdown
---
allowed-tools: Read, Write, Edit, Bash
description: Brief description of agent purpose
---

# Agent Name

Detailed description of agent capabilities and role.

## Core Capabilities

### Capability 1
Description and details

### Capability 2
Description and details

## Standards Compliance

How this agent follows project standards

## Typical Workflows

Common usage patterns and examples
```

### Metadata Fields

- **allowed-tools**: Comma-separated list of tools the agent can use
- **description**: One-line summary of agent purpose

## Tool Access Patterns

### Read-Only Agents
Agents that analyze without modifying:
- **Tools**: Read, Grep, Glob, Bash (read-only commands)
- **Examples**: debug-specialist, complexity-estimator

### Writing Agents
Agents that create or modify content:
- **Tools**: Read, Write, Edit, Bash
- **Examples**: plan-architect, implementation-executor, spec-updater

### Research Agents
Agents that gather external information:
- **Tools**: Read, Write, Grep, Glob, WebSearch
- **Examples**: research-specialist

### Coordination Agents
Agents that orchestrate other agents:
- **Tools**: Read, Bash, Task
- **Examples**: implementer-coordinator

### Classification Agents
Agents with minimal/no tools for fast classification:
- **Tools**: None or Read only
- **Examples**: plan-complexity-classifier

## Agent Invocation

Agents are typically invoked by commands, not directly by users.

### From Commands
```markdown
I'll invoke the implementation-executor agent to implement this phase.

[Invoke implementation-executor with context]
```

### Context Passing
When invoking an agent, provide:
- **Task description**: What needs to be done
- **Relevant files**: Files the agent should focus on
- **Standards**: CLAUDE.md sections to follow
- **Constraints**: Any limitations or requirements

## Best Practices

### Agent Design
- **Single responsibility**: Each agent has one clear purpose
- **Minimal tool access**: Only tools necessary for the agent's role
- **Clear instructions**: Detailed capability descriptions
- **Standards awareness**: Reference CLAUDE.md sections

### Tool Selection
- **Read-only when possible**: Prefer analysis over modification
- **Bash for verification**: Allow running tests or checks
- **TodoWrite for tracking**: Enable progress visibility in multi-step tasks

### Error Handling
- **Graceful degradation**: Handle missing tools or files
- **Clear reporting**: Explain what was done and what failed
- **Non-blocking**: Don't halt workflows on non-critical failures

## Creating Custom Agents

### Step 1: Define Purpose
Identify the specific task or domain the agent will handle.

### Step 2: Determine Tools
Choose minimal tools needed for the agent's responsibilities.

### Step 3: Write Definition
Create agent markdown file with metadata and instructions.

```bash
# Create new agent
nvim .claude/agents/your-agent.md
```

### Step 4: Document Capabilities
Clearly describe what the agent can and cannot do.

### Step 5: Test
Invoke the agent from a command and verify behavior.

## Agent Communication

### Input
Agents receive:
- **Task context**: Description of what to do
- **File paths**: Relevant files to work with
- **Standards**: CLAUDE.md sections to follow
- **State**: Current project state

### Output
Agents provide:
- **Completion status**: Success or failure
- **Results**: What was created or found
- **Next steps**: Recommendations for follow-up
- **Issues**: Problems encountered

## Integration with Commands

Commands orchestrate agents to accomplish complex workflows:

```
/plan
  ├── plan-complexity-classifier → Assess complexity
  ├── research-specialist → Gather context
  └── plan-architect → Create implementation plan

/build
  ├── implementer-coordinator → Orchestrate wave execution
  │   └── implementation-executor → Execute phase tasks
  │       └── spec-updater → Track progress
  └── debug-analyst → Investigate failures

/debug
  ├── research-specialist → Analyze codebase
  ├── debug-analyst → Test hypotheses
  └── debug-specialist → Root cause analysis

/expand, /collapse
  └── complexity-estimator → Assess complexity
```

### /expand-phase Integration

**Agent Usage Pattern**: Behavioral Injection

`/expand-phase` uses a unique pattern: **general-purpose agents** with **behavioral guidelines** from agent definition files.

**Why**: Claude Code only supports 3 agent types (general-purpose, statusline-setup, output-style-setup). We simulate specialized agents by having general-purpose agents read and follow behavior definitions.

**Invocation**:
```markdown
Task tool:
  subagent_type: general-purpose  # Only valid type
  prompt: |
    Read and follow: .claude/agents/research-specialist.md

    [Agent-specific instructions]
```

**Agent Behaviors Used**:
- **research-specialist**: Default for codebase analysis (complex phases)
- **debug-analyst**: For refactor/consolidation phases
- **plan-architect**: For very complex phase structure analysis

**Complexity Detection**:
- Simple phases (≤5 tasks, <10 files): Direct expansion, no agent
- Complex phases (>5 tasks, ≥10 files, or keywords): Agent-assisted research

**Synthesis**:
Agent provides 200-250 word research → Claude synthesizes into 300-500+ line detailed specification

**Benefits**:
- Real file:line references from research
- Concrete code examples based on patterns found
- Testing strategy based on current codebase state
- Implementation steps use actual structures

See `.claude/commands/expand-phase.md` for detailed agent usage patterns.

## Neovim Integration

Agents in this directory are integrated with the Neovim artifact picker, appearing in two contexts:

### Picker Display Modes

1. **Nested Under Commands** - Agents appear indented under commands that use them
   ```
   * plan                        Create implementation plans
     ├─ [agent] plan-architect  AI planning specialist
     └─ list-reports            List available research reports
   ```

2. **Standalone Agents Section** - Agents not associated with any command appear in a dedicated [Agents] category

### Accessing Agents via Picker

- **Keybinding**: `<leader>ac` in normal mode
- **Command**: `:ClaudeCommands`
- **Category**: [Agents] section (for standalone) or nested under commands

### Picker Features for Agents

**Visual Display**:
- Agent names prefixed with `[agent]` tag
- Local agents marked with `*` prefix
- Nested under parent commands with tree characters
- Cross-references showing which commands use each agent

**Preview Features**:
- Agent description and capabilities
- Allowed tools list
- "Commands that use this agent" section with tree-formatted list
- File location and local/global status

**Quick Actions**:
- `<CR>` - Open agent file for editing
- `<C-l>` - Load agent locally to project
- `<C-g>` - Update from global version
- `<C-s>` - Save local agent to global
- `<C-e>` - Edit agent file in buffer
- `<C-u>`/`<C-d>` - Scroll preview up/down

**Example Workflow**:
```vim
" Open picker
:ClaudeCommands

" Navigate to plan-architect agent
" Preview shows: "Commands that use this agent: ├─ plan, └─ revise"
" Press <C-e> to edit agent definition
```

### Agent Cross-References

The picker automatically displays which commands use each agent in the preview pane:

```
Agent: plan-architect

Description: AI planning specialist

Allowed Tools: ReadFile, WriteFile, SlashCommand

Commands that use this agent:
   ├─ plan
   └─ revise

File: /home/user/.claude/agents/plan-architect.md
```

This helps discover agent usage patterns and identify agents suitable for reuse in new commands.

### Documentation

- [Neovim Claude Integration](../../nvim/lua/neotex/plugins/ai/claude/README.md) - Integration overview
- [Commands Picker](../../nvim/lua/neotex/plugins/ai/claude/commands/README.md) - Picker documentation
- [Picker Implementation](../../nvim/lua/neotex/plugins/ai/claude/commands/picker.lua) - Source code

## Standards Compliance

All agents follow documentation standards:

- **NO emojis** in file content
- **Unicode box-drawing** for diagrams
- **Clear, concise** language
- **Code examples** with syntax highlighting
- **CommonMark** specification

See [/home/benjamin/.config/nvim/docs/CODE_STANDARDS.md](../../nvim/docs/CODE_STANDARDS.md) for complete standards.

## Navigation

### Agent Definitions

**Classification Agents**:
- [plan-complexity-classifier.md](plan-complexity-classifier.md) - Feature complexity assessment
- [complexity-estimator.md](complexity-estimator.md) - Context-aware complexity analysis

**Research Agents**:
- [research-specialist.md](research-specialist.md) - Research and reports
- [research-sub-supervisor.md](research-sub-supervisor.md) - Coordinate research workers

**Planning Agents**:
- [plan-architect.md](plan-architect.md) - Implementation planning
- [cleanup-plan-architect.md](cleanup-plan-architect.md) - CLAUDE.md optimization plans

**Implementation Agents**:
- [implementer-coordinator.md](implementer-coordinator.md) - Wave-based parallel execution
- [implementation-executor.md](implementation-executor.md) - Single phase execution
- [spec-updater.md](spec-updater.md) - Artifact updates and progress

**Debug/Analysis Agents**:
- [debug-specialist.md](debug-specialist.md) - Root cause analysis
- [debug-analyst.md](debug-analyst.md) - Parallel hypothesis testing
- [claude-md-analyzer.md](claude-md-analyzer.md) - CLAUDE.md structure analysis
- [docs-structure-analyzer.md](docs-structure-analyzer.md) - Documentation organization
- [docs-bloat-analyzer.md](docs-bloat-analyzer.md) - Semantic bloat detection
- [docs-accuracy-analyzer.md](docs-accuracy-analyzer.md) - Documentation accuracy

**Utility Agents**:
- [doc-converter.md](doc-converter.md) - Convert Word/PDF to Markdown
- [todo-analyzer.md](todo-analyzer.md) - Plan status classification for TODO.md

### Subdirectories
- [prompts/](prompts/README.md) - Agent evaluation prompt templates
- [shared/](shared/README.md) - Shared protocols and guidelines

### Related
- [← Parent Directory](../README.md)
- [commands/](../commands/README.md) - Commands that use agents
- [docs/archive/guides/using-agents.md](../docs/archive/guides/using-agents.md) - Integration guide (archived)
- [docs/guides/development/agent-development/agent-development-fundamentals.md](../docs/guides/development/agent-development/agent-development-fundamentals.md) - Development guide

## Examples

### Invoking Research Specialist
```markdown
I'll use the research-specialist agent to investigate options.

Topic: Evaluate TTS engines (espeak-ng vs festival vs pico-tts)
Output: Research report in specs/reports/
Focus: Performance, voice quality, installation complexity
```

### Invoking Plan Architect
```markdown
I'll use the plan-architect agent to design the implementation.

Requirements: Add user authentication to the application
Scope: Backend API, database models, security considerations
Output: Implementation plan with phases and tasks
```

### Invoking Debug Specialist
```markdown
I'll use the debug-specialist agent to investigate the issue.

Problem: Build command fails with state transition error
Symptoms: COMPLETE markers not being added correctly
Output: Root cause analysis and fix recommendations
```
