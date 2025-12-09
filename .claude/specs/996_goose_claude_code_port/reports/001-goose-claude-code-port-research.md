# Claude Code to Goose Migration Research Report

## Metadata
- **Date**: 2025-12-05
- **Agent**: research-specialist
- **Topic**: Porting Claude Code slash commands, subagents, and infrastructure to Goose
- **Report Type**: Migration analysis and compatibility assessment

## Executive Summary

This research analyzes the feasibility and approach for porting Claude Code's slash commands, subagents, and supporting infrastructure to Block's Goose AI framework. The analysis reveals that while both systems share similar conceptual foundations (autonomous AI agents with extensible capabilities), their architectural implementations differ significantly, requiring careful mapping and adaptation rather than direct porting.

**Key Finding**: Goose uses a **recipe-based declarative YAML system** for workflows combined with **MCP servers for extensions**, while Claude Code uses **markdown-based behavioral files** with **bash-heavy orchestration scripts**. A migration is feasible but requires architectural transformation.

## Findings

### 1. Architecture Comparison

#### Claude Code Structure
```
.claude/
  commands/       # Slash commands (markdown with frontmatter)
  agents/         # Subagent behavioral files (markdown)
  lib/            # Bash libraries (state management, validation)
  docs/           # Documentation
  specs/          # Workflow artifacts (plans, reports)
```

**Command Pattern**: Markdown files with YAML frontmatter define allowed tools, model preferences, and execution instructions with embedded bash blocks.

**Agent Pattern**: Behavioral markdown files that provide structured instructions for subagent task delegation via the Task tool.

**State Management**: Custom bash libraries (state-persistence.sh, workflow-state-machine.sh) handle workflow state across conversation boundaries.

#### Goose Structure
```
~/.config/goose/
  config.yaml        # Global configuration (providers, models, extensions)
  recipes/           # Global reusable recipes
  .goosehints        # Global context hints

PROJECT_ROOT/
  .goose/
    recipes/         # Project-specific recipes
  .goosehints        # Project context hints
  recipe.yaml        # Ad-hoc recipe files
```

**Recipe Pattern**: YAML files defining version, title, instructions, parameters, extensions, and optional structured output schemas.

**Subagent Pattern**: Goose subagents are spawned dynamically either autonomously or via natural language requests, with recipe-based configuration.

**State Management**: Goose manages sessions automatically with conversation history; recipes are stateless templates executed fresh each time.

### 2. Feature Mapping

| Claude Code Feature | Goose Equivalent | Migration Complexity |
|---------------------|------------------|----------------------|
| Slash commands (`.claude/commands/*.md`) | Recipes (`.goose/recipes/*.yaml`) | Medium - format transformation |
| Agents (`.claude/agents/*.md`) | Subrecipes + MCP servers | High - architectural change |
| CLAUDE.md context | `.goosehints` files | Low - conceptual equivalent |
| Bash libraries (`.claude/lib/`) | No direct equivalent | High - must port to recipes or MCP |
| State machine orchestration | Recipe retry + response validation | High - different paradigm |
| Task tool delegation | Subagent spawning | Medium - similar concept |
| Plan mode workflows | `/plan` command + recipes | Medium - similar concept |
| Error logging (errors.jsonl) | Native logging (goose logs) | Low - use built-in |
| Specs/artifacts directory | Custom directory structure | Low - compatible |

### 3. Configuration System Comparison

#### Claude Code Configuration
- **CLAUDE.md**: Project-specific instructions merged hierarchically
- **Frontmatter fields**: `allowed-tools`, `description`, `model`, `dependent-agents`
- **Environment detection**: Git root or .claude directory presence
- **Tool permissions**: Implicit via allowed-tools frontmatter

#### Goose Configuration
- **config.yaml**: Global settings for providers, models, and extensions
- **Recipe fields**: `version`, `title`, `instructions`, `parameters`, `extensions`, `settings`
- **Environment detection**: Working directory and recipe paths
- **Tool permissions**: Explicit via goose configure and permission.yaml

**Key Configuration Differences**:

1. **Model Selection**:
   - Claude Code: Frontmatter `model` field per command/agent
   - Goose: Global default in config.yaml, overridable per recipe in `settings`

2. **Extension/Tool Management**:
   - Claude Code: `allowed-tools` whitelist per file
   - Goose: Global extensions in config.yaml + per-recipe extension overrides

3. **Context Files**:
   - Claude Code: CLAUDE.md with hierarchical merging
   - Goose: .goosehints with hierarchical loading + @ syntax for file inclusion

### 4. Command-to-Recipe Translation

#### Claude Code Command Structure
```markdown
---
allowed-tools: Task, TodoWrite, Bash, Read, Grep, Glob, Write
argument-hint: <feature-description> [--file <path>] [--complexity 1-4]
description: Research and create new implementation plan workflow
command-type: primary
dependent-agents:
  - research-specialist
  - plan-architect
---

# /create-plan - Research-and-Plan Workflow Command

## Block 1: Setup
Execute this bash block:
[embedded bash with state initialization]

## Block 2: Task Invocation
USE the Task tool to invoke research-specialist...
```

#### Equivalent Goose Recipe Structure
```yaml
version: "1.0.0"
title: "Create Implementation Plan"
description: "Research and create new implementation plan workflow"

instructions: |
  You are executing a research-and-plan workflow that creates comprehensive
  research reports and generates an implementation plan based on findings.

  1. Research the codebase for relevant patterns and existing code
  2. Identify best practices and architectural considerations
  3. Create a detailed implementation plan with phases

  Feature to plan: {{ feature_description }}

parameters:
  - key: feature_description
    input_type: string
    requirement: required
    description: "Feature or task description to plan"
  - key: complexity
    input_type: number
    requirement: optional
    default: 3
    description: "Research complexity (1-4)"

extensions:
  - type: stdio
    name: developer
    cmd: goose-developer
    bundled: true
    timeout: 300
  - type: stdio
    name: filesystem
    cmd: goose-fs
    bundled: true
    timeout: 60

settings:
  goose_provider: anthropic
  goose_model: claude-sonnet-4-20250514

sub_recipes:
  - name: research-specialist
    path: ./research-specialist.yaml
  - name: plan-architect
    path: ./plan-architect.yaml

response:
  json_schema:
    type: object
    properties:
      plan_path:
        type: string
        description: "Path to created plan file"
      research_reports:
        type: array
        items:
          type: string
    required: [plan_path]
```

### 5. Subagent Migration Strategy

#### Claude Code Agent Pattern
Agents are markdown files with behavioral instructions, invoked via Task tool:
```markdown
---
allowed-tools: Read, Write, Grep, Glob
description: Specialized in codebase research and report creation
model: sonnet-4.5
---

# Research Specialist Agent

STEP 1: Receive and verify report path
STEP 2: Create report file FIRST
STEP 3: Conduct research using tools
STEP 4: Return completion signal
```

#### Goose Subagent Options

**Option A: Subrecipes (Recommended)**
```yaml
# research-specialist.yaml
version: "1.0.0"
title: "Research Specialist"
description: "Specialized in codebase research and report creation"

instructions: |
  You are a research specialist conducting codebase analysis.

  1. Verify the report path: {{ report_path }}
  2. Create the report file with initial structure
  3. Search codebase for relevant patterns
  4. Document findings in the report file

  Return: REPORT_CREATED: {{ report_path }}

parameters:
  - key: report_path
    input_type: string
    requirement: required
  - key: research_topic
    input_type: string
    requirement: required

extensions:
  - type: stdio
    name: developer
    cmd: goose-developer
    bundled: true
```

**Option B: MCP Server (For Complex Agents)**
Build a custom MCP server that exposes agent capabilities as tools:
```yaml
extensions:
  - type: stdio
    name: research-specialist-mcp
    cmd: npx
    args: ["-y", "@your-org/research-specialist-mcp"]
    timeout: 300
```

**Option C: External Subagents**
Integrate Claude as an external AI agent via MCP:
```yaml
extensions:
  - type: stdio
    name: claude-agent
    cmd: mcp-claude-agent
    args: ["--model", "claude-sonnet-4-20250514"]
```

### 6. Bash Library Migration

The Claude Code bash libraries provide critical functionality:

| Library | Function | Goose Approach |
|---------|----------|----------------|
| `state-persistence.sh` | Workflow state across blocks | Use recipe parameters + file-based state |
| `workflow-state-machine.sh` | State transitions and validation | Recipe retry config + shell commands |
| `error-handling.sh` | Error logging and trapping | Native goose logging + shell traps |
| `validation-utils.sh` | Artifact validation | Shell commands in instructions |
| `workflow-initialization.sh` | Path and directory setup | Shell commands in instructions |

**Migration Approach**: Most bash functionality can be embedded directly in recipe instructions or converted to simple shell scripts invoked via `goose run`:

```yaml
instructions: |
  # State initialization (equivalent to workflow-initialization.sh)
  Execute: mkdir -p .goose/tmp/workflow_{{ workflow_id }}

  # Validation (equivalent to validation-utils.sh)
  Verify the file exists and has minimum size:
  - File: {{ report_path }}
  - Minimum size: 100 bytes

  If validation fails, return error: VALIDATION_ERROR: [details]
```

### 7. Key Differences Requiring Adaptation

#### 7.1 Orchestration Model
- **Claude Code**: Command orchestrator executes bash blocks sequentially, invoking subagents via Task tool
- **Goose**: Recipe-based declarative system; orchestration via subrecipes and sequential_when_repeated

**Adaptation**: Convert multi-block bash orchestration to chained subrecipe calls with explicit parameter passing.

#### 7.2 State Management
- **Claude Code**: Explicit state files sourced between bash blocks
- **Goose**: Session-based state; recipes are stateless templates

**Adaptation**:
- Use file-based state storage (write/read from .goose/tmp/)
- Pass state via recipe parameters
- Use response validation for completion signals

#### 7.3 Hard Barrier Pattern
- **Claude Code**: Pre-calculate paths, invoke agent, validate output exists
- **Goose**: Recipe retry with shell validation checks

**Goose Equivalent**:
```yaml
retry:
  max_retries: 3
  timeout_seconds: 300
  checks:
    - type: shell
      command: "test -f {{ report_path }} && test $(wc -c < {{ report_path }}) -gt 100"
  on_failure: "rm -f {{ report_path }}"
```

#### 7.4 Hierarchical Context
- **Claude Code**: CLAUDE.md merged from project root through subdirectories
- **Goose**: .goosehints loaded hierarchically with same behavior

**Adaptation**: Direct translation - rename CLAUDE.md to .goosehints with minor syntax adjustments for @ file inclusion.

### 8. Implementation Roadmap

#### Phase 1: Foundation (Estimated: 2-4 hours)
1. Create `.goose/` directory structure in project
2. Create `.goosehints` from CLAUDE.md content
3. Setup global goose configuration for Anthropic provider

#### Phase 2: Simple Commands (Estimated: 4-8 hours)
1. Port simple commands (/setup, /todo) as basic recipes
2. Test parameter passing and file operations
3. Validate extension access (filesystem, developer)

#### Phase 3: Research Workflows (Estimated: 8-16 hours)
1. Port research-specialist as subrecipe
2. Port /research command as parent recipe with subrecipe call
3. Implement state management via files
4. Add retry/validation for hard barrier pattern

#### Phase 4: Planning Workflows (Estimated: 8-16 hours)
1. Port plan-architect as subrecipe
2. Port /create-plan with research + planning phases
3. Implement multi-step orchestration

#### Phase 5: Implementation Workflows (Estimated: 16-24 hours)
1. Port implementer-coordinator
2. Port /implement with phase tracking
3. Handle complex state transitions

#### Phase 6: Testing and Debugging (Estimated: 8-16 hours)
1. Port test-executor
2. Port /test command
3. Integrate with project test suites

### 9. Limitations and Considerations

#### 9.1 What Cannot Be Directly Ported
1. **Inline bash blocks**: Goose instructions are natural language; complex bash must be external scripts
2. **State machine library**: No direct equivalent; requires architectural redesign
3. **Error logging format**: errors.jsonl replaced by goose's native logging

#### 9.2 Feature Gaps in Goose
1. **No equivalent to TodoWrite tool**: Must use file-based tracking or custom MCP
2. **Limited subagent control**: Cannot restrict tools as granularly as allowed-tools
3. **No built-in checkbox tracking**: Must implement in recipe instructions

#### 9.3 Advantages of Goose
1. **Declarative recipes**: Easier to understand and modify than embedded bash
2. **Built-in retry/validation**: retry config handles hard barrier pattern elegantly
3. **MCP ecosystem**: Access to extensive MCP server library
4. **Multi-model support**: Easy provider/model switching per recipe
5. **Parallel subagent execution**: Native support for concurrent tasks

## Recommendations

### Short-Term (Quick Wins)
1. **Create .goosehints**: Port CLAUDE.md content with minimal changes
2. **Simple recipe POC**: Port /research as first recipe to validate approach
3. **Test subrecipe pattern**: Verify research-specialist works as subrecipe

### Medium-Term (Core Migration)
1. **Design state pattern**: Establish file-based state management convention
2. **Create recipe templates**: Standardize recipe structure for commands
3. **Port workflow commands**: /create-plan, /implement, /test in order

### Long-Term (Full Migration)
1. **Custom MCP servers**: Build MCP servers for specialized capabilities
2. **Automated conversion**: Script to convert .md commands to .yaml recipes
3. **Documentation**: Create comprehensive Goose-native documentation

## Appendix: Reference Implementation

### Example: /research as Goose Recipe

```yaml
# .goose/recipes/research.yaml
version: "1.0.0"
title: "Research Workflow"
description: "Research a topic and create comprehensive analysis report"

instructions: |
  You are conducting research for the topic: {{ topic }}

  ## Phase 1: Setup
  Create the research directory and report file:
  - Directory: .claude/specs/{{ topic_slug }}/reports/
  - Report path: .claude/specs/{{ topic_slug }}/reports/001-{{ topic_slug }}.md

  ## Phase 2: Research
  Search the codebase and web for relevant information about {{ topic }}.
  Use the developer extension to read files and grep for patterns.

  ## Phase 3: Documentation
  Write comprehensive findings to the report file with sections:
  - Executive Summary
  - Findings
  - Recommendations

  ## Phase 4: Completion
  Return: REPORT_CREATED: [report_path]

parameters:
  - key: topic
    input_type: string
    requirement: required
    description: "Topic to research"
  - key: topic_slug
    input_type: string
    requirement: optional
    default: "research"
    description: "URL-safe topic identifier"
  - key: complexity
    input_type: number
    requirement: optional
    default: 2
    description: "Research depth (1-4)"

extensions:
  - type: stdio
    name: developer
    cmd: goose-developer
    bundled: true
    timeout: 300
  - type: stdio
    name: filesystem
    cmd: goose-fs
    bundled: true

settings:
  goose_provider: anthropic
  goose_model: claude-sonnet-4-20250514
  temperature: 0.3

retry:
  max_retries: 2
  timeout_seconds: 600
  checks:
    - type: shell
      command: "test -f .claude/specs/{{ topic_slug }}/reports/001-{{ topic_slug }}.md"
```

### Example: Goose CLI Invocation
```bash
# Run the research recipe
goose run --recipe .goose/recipes/research.yaml \
  --params topic="authentication patterns" \
  --params topic_slug="auth_patterns" \
  --params complexity=3

# Or use interactive session
goose session
> Use the research recipe to investigate JWT token handling
```

## Conclusion

Migrating Claude Code's infrastructure to Goose is feasible but requires substantial architectural adaptation. The key insight is that Goose's recipe-based declarative system, while different from Claude Code's embedded bash approach, can achieve equivalent functionality through:

1. **Subrecipes** for agent delegation
2. **File-based state** for workflow persistence
3. **Retry configuration** for hard barrier validation
4. **MCP servers** for specialized tool capabilities

The migration should be approached incrementally, starting with simple commands to validate patterns before tackling complex multi-phase workflows. The estimated total effort is 46-84 hours depending on thoroughness and testing requirements.
