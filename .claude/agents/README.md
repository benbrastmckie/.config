# Agents Directory

Specialized AI agent definitions for Claude Code. Each agent is a focused assistant with specific capabilities, tool access, and expertise designed to handle particular aspects of development workflows.

**Current Agent Count**: 19 specialized agents (22 - 4 archived + 1 new)

## Recent Changes

### Agent Consolidation (2025-10-27)
Consolidated overlapping agents and refactored deterministic logic to utility libraries:

**Agents Consolidated**:
- `expansion-specialist.md` + `collapse-specialist.md` → **plan-structure-manager.md** (95% overlap eliminated, 506 lines saved)
- `plan-expander.md` → **Archived** (pure coordination wrapper with no behavioral logic, 562 lines saved)
- `git-commit-helper.md` → **Refactored to .claude/lib/git-commit-utils.sh** (deterministic logic moved to library, 100 lines saved, zero agent invocation overhead)

**Impact**:
- Agents: 22 → 19 (14% reduction)
- Code reduction: 1,168 lines saved
- Performance: Zero invocation overhead for git commit message generation (now library function)
- Architecture: Unified operation parameter pattern (expand/collapse)
- Maintainability: 3 fewer agents to maintain, clearer patterns

### Registry Update (2025-10-27)
Added 5 missing agents to registry for complete tracking:

**Agents Added to Registry**:
- `doc-converter-usage.md` → Documentation file (moved to docs/ in Phase 2)
- `git-commit-helper.md` → Specialized (refactored to .claude/lib/git-commit-utils.sh in Phase 5)
- `implementation-executor.md` → Hierarchical implementation agent
- `implementer-coordinator.md` → Hierarchical coordinator agent
- `research-synthesizer.md` → Specialized research agent

**Impact**:
- Registry: 17 → 22 entries (100% coverage)
- Agent discovery improved
- Metrics tracking enabled for all agents

### Agent Cleanup (2025-10-26)
Removed deprecated agent to improve maintainability:

**Agent Removed**:
- `location-specialist.md` → **Archived** (superseded by unified location detection library)

**Impact**:
- Agents: 22 → 21 files (4.5% reduction, ~14KB saved)
- Functionality preserved in `.claude/lib/unified-location-detection.sh`
- Unified codebase with library-based location detection

### Orchestration Integration (2025-10-12)
Agents enhanced for comprehensive multi-phase workflow orchestration:

**research-specialist**:
- Direct file creation for research reports in `specs/reports/{topic}/`
- Topic-based organization with incremental numbering per topic
- Structured metadata including workflow context and specs directory
- Integration with /orchestrate research phase

**debug-specialist**:
- File-based debug reports in `debug/{topic}/` directory
- Persistent debugging documentation separate from gitignored specs/
- Integration with /orchestrate debugging loop
- Structured investigation reports with root cause analysis

**plan-architect**:
- Report verification and linking in plan metadata
- Cross-referencing research reports in implementation plans
- Enhanced metadata for research-driven planning
- Integration with /orchestrate planning phase

**Benefits**:
- End-to-end workflow coordination through /orchestrate
- Persistent documentation for all workflow phases
- Clear artifact organization (specs/ for plans/reports, debug/ for investigations)
- Complete traceability from research through debugging

### Shared Protocols (2025-10-06)
Agents now reference shared protocol documentation in `.claude/agents/shared/`:
- `progress-streaming-protocol.md` - Standard progress reporting format
- `error-handling-guidelines.md` - Consistent error handling patterns

**Benefits**:
- ~200 LOC reduction through duplication removal
- Standardized behavior across all agents
- Easier agent creation with documented patterns

### Agent Standardization (2025-10-06)
All agents now follow consistent structure:
1. **Core Responsibility** - Single clear purpose
2. **Capabilities** - What the agent can do
3. **Protocols** - References to shared documentation
4. **Specialization** - Unique agent-specific logic

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

### code-reviewer.md
**Purpose**: Analyze code for quality, standards compliance, and potential issues

**Capabilities**:
- Code quality assessment
- Standards compliance checking
- Bug detection
- Performance analysis
- Security review

**Allowed Tools**: Read, Grep, Glob, Bash

**Typical Use Cases**:
- Pre-commit code review
- Refactoring analysis
- Quality assurance checks

---

### code-writer.md
**Purpose**: Write and modify code following project standards

**Capabilities**:
- Code generation
- Feature implementation
- Bug fixes
- Refactoring
- Standards-compliant formatting

**Allowed Tools**: Read, Write, Edit, Bash, TodoWrite

**Typical Use Cases**:
- Implementing features from specs
- Fixing identified bugs
- Refactoring code sections

---

### debug-specialist.md
**Purpose**: Investigate and diagnose issues without making changes

**Capabilities**:
- Error analysis
- Log inspection
- Environment investigation
- Root cause analysis
- Diagnostic report generation
- File-based debug reports for orchestrated workflows
- Persistent debugging documentation in `debug/{topic}/`

**Allowed Tools**: Read, Grep, Glob, Bash, WebSearch, Write

**Typical Use Cases**:
- Troubleshooting failures
- Understanding error messages
- Investigating performance issues
- Creating debug reports during /orchestrate debugging loop

---

### doc-converter.md
**Purpose**: Convert Word (DOCX) and PDF files to Markdown format

**Capabilities**:
- Batch document conversion (DOCX and PDF)
- MarkItDown-based DOCX and PDF conversion (primary tool)
- Pandoc-based DOCX conversion fallback
- PyMuPDF4LLM PDF conversion backup (fast, lightweight)
- Image extraction and organization
- Conversion validation and quality checks
- Progress reporting and statistics

**Allowed Tools**: Read, Grep, Glob, Bash, Write

**Typical Use Cases**:
- Converting legacy documentation to Markdown
- Batch processing document archives
- Migrating Word docs to version control
- Extracting content from PDF reports

---

### doc-writer.md
**Purpose**: Create and update documentation

**Capabilities**:
- README generation
- API documentation
- Usage examples
- Architecture diagrams
- Standards compliance

**Allowed Tools**: Read, Write, Edit, Grep, Glob

**Typical Use Cases**:
- Creating missing READMEs
- Updating documentation after changes
- Generating API documentation

---

### github-specialist.md
**Purpose**: Manage GitHub operations including PRs, issues, and CI/CD monitoring

**Capabilities**:
- Pull request creation with rich metadata
- Issue management and categorization
- CI/CD workflow monitoring
- Repository state verification
- GitHub CLI integration

**Allowed Tools**: Read, Grep, Glob, Bash

**Typical Use Cases**:
- Creating PRs after implementation completion
- Generating issues from debug reports
- Monitoring CI workflow status
- Linking PRs to implementation plans and reports

---

### metrics-specialist.md
**Purpose**: Analyze performance metrics and generate insights

**Capabilities**:
- Metrics analysis
- Performance trend identification
- Bottleneck detection
- Optimization recommendations
- Report generation

**Allowed Tools**: Read, Grep, Bash

**Typical Use Cases**:
- Monthly performance reviews
- Identifying slow commands
- Optimization planning

---

### plan-architect.md
**Purpose**: Design implementation plans from requirements

**Capabilities**:
- Requirements analysis
- Architecture design
- Phase breakdown
- Risk assessment
- Success criteria definition

**Allowed Tools**: Read, Write, Grep, Glob

**Typical Use Cases**:
- Creating implementation plans
- Designing feature architecture
- Breaking down complex tasks

---

### research-specialist.md
**Purpose**: Conduct research and generate comprehensive reports

**Capabilities**:
- Technology investigation
- Best practices research
- Feasibility analysis
- Alternative comparison
- Report writing
- Direct report file creation in `specs/reports/{topic}/`
- Topic-based organization with incremental numbering
- Integration with /orchestrate research phase

**Allowed Tools**: Read, Write, Grep, Glob, WebSearch

**Typical Use Cases**:
- Technology evaluation
- Problem investigation
- Pre-implementation research
- Research phase execution in orchestrated workflows

---

### test-specialist.md
**Purpose**: Run tests, analyze results, and ensure quality

**Capabilities**:
- Test execution
- Result analysis
- Failure diagnosis
- Coverage assessment
- Test improvement suggestions

**Allowed Tools**: Read, Bash, Grep, Glob

**Typical Use Cases**:
- Running test suites
- Analyzing test failures
- Validating implementations

---

### complexity_estimator.md
**Purpose**: Provide context-aware complexity analysis for plan expansion/collapse decisions

**Capabilities**:
- Context-aware complexity estimation (1-10 scale)
- Architectural significance assessment
- Integration complexity analysis
- Risk and testing requirements evaluation
- JSON-structured recommendations with reasoning

**Allowed Tools**: Read, Grep, Glob

**Typical Use Cases**:
- Auto-analysis mode in /expand command
- Auto-analysis mode in /collapse command
- Determining which phases warrant separate files
- Evaluating if expanded content can be collapsed

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
- **Examples**: code-reviewer, debug-specialist, metrics-specialist

### Writing Agents
Agents that create or modify content:
- **Tools**: Read, Write, Edit, Bash
- **Examples**: code-writer, doc-writer, plan-architect

### Research Agents
Agents that gather external information:
- **Tools**: Read, Write, Grep, Glob, WebSearch
- **Examples**: research-specialist

### Testing Agents
Agents that execute and analyze tests:
- **Tools**: Read, Bash, Grep, Glob
- **Examples**: test-specialist

## Agent Invocation

Agents are typically invoked by commands, not directly by users.

### From Commands
```markdown
I'll invoke the code-writer agent to implement this feature.

[Invoke code-writer with context]
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
/implement
  ├── plan-architect → Design phases
  ├── code-writer → Implement each phase
  ├── test-specialist → Verify implementation
  └── doc-writer → Update documentation

/report
  ├── research-specialist → Gather information
  └── doc-writer → Format report

/debug
  ├── debug-specialist → Investigate issue
  └── code-writer → Apply fixes (if requested)

/expand-phase (agent-assisted for complex phases)
  └── general-purpose + research-specialist behavior → Research phase context
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
- **code-reviewer**: For refactor/consolidation phases
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
- [code-reviewer.md](code-reviewer.md) - Code quality analysis
- [code-writer.md](code-writer.md) - Code implementation
- [complexity-estimator.md](complexity-estimator.md) - Context-aware complexity analysis
- [debug-specialist.md](debug-specialist.md) - Issue investigation
- [doc-converter.md](doc-converter.md) - Convert Word/PDF to Markdown
- [doc-writer.md](doc-writer.md) - Documentation creation
- [github-specialist.md](github-specialist.md) - GitHub operations and PR management
- [metrics-specialist.md](metrics-specialist.md) - Performance analysis
- [plan-architect.md](plan-architect.md) - Implementation planning
- [research-specialist.md](research-specialist.md) - Research and reports
- [test-specialist.md](test-specialist.md) - Testing and validation

### Subdirectories
- [prompts/](prompts/README.md) - Agent evaluation prompt templates
- [shared/](shared/README.md) - Shared protocols and guidelines

### Related
- [← Parent Directory](../README.md)
- [commands/](../commands/README.md) - Commands that use agents
- [docs/guides/using-agents.md](../docs/guides/using-agents.md) - Integration guide
- [docs/guides/agent-development-guide.md](../docs/guides/agent-development-guide.md) - Development guide

## Examples

### Invoking Code Writer
```markdown
I'll use the code-writer agent to implement the new feature.

Task: Implement user authentication module
Files: src/auth.lua
Standards: Follow CLAUDE.md code standards (2 space indent, snake_case)
```

### Invoking Research Specialist
```markdown
I'll use the research-specialist agent to investigate options.

Topic: Evaluate TTS engines (espeak-ng vs festival vs pico-tts)
Output: Research report in specs/reports/
Focus: Performance, voice quality, installation complexity
```

### Invoking Test Specialist
```markdown
I'll use the test-specialist agent to validate the changes.

Target: Run full test suite
Analyze: Any failures or regressions
Report: Coverage and quality metrics
```
