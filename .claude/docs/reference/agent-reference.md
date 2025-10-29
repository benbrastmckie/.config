# Agent Reference

Quick lookup for all available specialized agents in the Claude Code system.

## Purpose

This reference provides:
- Alphabetical agent listing
- Agent capabilities summary
- Tool restrictions per agent
- Commands that use each agent
- Links to full agent definitions

Use this as a quick decision guide for agent selection in command development.

For command architecture standards and agent invocation patterns, see [Command Architecture Standards](command_architecture_standards.md).

## Agent Directory

### code-reviewer
**Purpose**: Reviews code against project standards and identifies quality issues

**Capabilities**:
- Standards compliance review
- Code quality analysis
- Refactoring opportunity identification
- Review report generation with severity levels

**Allowed Tools**: Read, Grep, Glob, Bash

**Used By**: /refactor, /orchestrate (optional pre-commit)

**Definition**: [.claude/agents/code-reviewer.md](../agents/code-reviewer.md)

---

### code-writer
**Purpose**: Generates and modifies code following project standards

**Capabilities**:
- Code generation for new features
- Bug fixes and modifications
- Standards-compliant formatting
- Test file creation

**Allowed Tools**: Read, Write, Edit, Bash, TodoWrite

**Used By**: /orchestrate (implementation phase), /orchestrate (fix application)

**Definition**: [.claude/agents/code-writer.md](../agents/code-writer.md)

---

### collapse_specialist
**Purpose**: Analyzes expanded plans for collapsing back to parent structure

**Capabilities**:
- Complexity re-analysis for expanded phases/stages
- Collapse recommendations with justification
- Determines if content can be safely merged

**Allowed Tools**: Read, Grep, Glob

**Used By**: /collapse (auto-analysis mode)

**Definition**: [.claude/agents/collapse_specialist.md](../agents/collapse_specialist.md)

---

### complexity_estimator
**Purpose**: Context-aware complexity analysis for plan expansion/collapse decisions

**Capabilities**:
- Architectural significance assessment
- Integration complexity scoring
- Risk and testing needs analysis
- JSON recommendations with 1-10 complexity scores

**Allowed Tools**: Read, Grep, Glob

**Used By**: /expand (auto-analysis mode), /collapse (auto-analysis mode)

**Definition**: [.claude/agents/complexity_estimator.md](../agents/complexity_estimator.md)

---

### debug-specialist
**Purpose**: Root cause analysis and diagnostic investigations

**Capabilities**:
- Issue investigation with evidence gathering
- Solution proposal with multiple options
- Debug report generation

**Allowed Tools**: Read, Bash, Grep, Glob, WebSearch

**Used By**: /debug, /orchestrate (debugging loop)

**Definition**: [.claude/agents/debug-specialist.md](../agents/debug-specialist.md)

---

### doc-converter
**Purpose**: Bidirectional document format conversion (Markdown, DOCX, PDF)

**Capabilities**:
- Convert between Markdown, Word (DOCX), and PDF formats
- Batch processing of multiple files
- Metadata preservation during conversion
- Format-specific styling and structure

**Allowed Tools**: Read, Write, Bash

**Used By**: /convert-docs

**Definition**: [.claude/agents/doc-converter.md](../agents/doc-converter.md)

---

### doc-converter-update
**Purpose**: Updates existing converted documents with new content

**Capabilities**:
- Incremental updates to converted documents
- Change tracking and version management
- Preserves formatting during updates

**Allowed Tools**: Read, Write, Edit, Bash

**Used By**: /convert-docs (update mode)

**Definition**: [.claude/agents/doc-converter-update.md](../agents/doc-converter-update.md)

---

### doc-converter-usage
**Purpose**: Demonstrates document conversion tool usage patterns

**Capabilities**:
- Example conversion workflows
- Common conversion scenarios
- Best practices for document conversion

**Allowed Tools**: Read, Bash

**Used By**: Internal documentation and examples

**Definition**: [.claude/agents/doc-converter-usage.md](../agents/doc-converter-usage.md)

---

### doc-writer
**Purpose**: Documentation creation and maintenance

**Capabilities**:
- README updates and creation
- Documentation synchronization
- Cross-referencing
- Unicode box-drawing diagrams

**Allowed Tools**: Read, Write, Edit, Grep, Glob

**Used By**: /document, /orchestrate (documentation phase)

**Definition**: [.claude/agents/doc-writer.md](../agents/doc-writer.md)

---

### expansion_specialist
**Purpose**: Analyzes phases for expansion into detailed specifications

**Capabilities**:
- Phase complexity analysis
- Expansion recommendations with justification
- Determines when expansion provides value

**Allowed Tools**: Read, Grep, Glob

**Used By**: /expand (auto-analysis mode)

**Definition**: [.claude/agents/expansion_specialist.md](../agents/expansion_specialist.md)

---

### github-specialist
**Purpose**: GitHub operations including PRs, issues, and CI/CD monitoring

**Capabilities**:
- PR creation with metadata
- Issue management
- CI workflow monitoring
- Primary tool: gh CLI via Bash

**Allowed Tools**: Read, Grep, Glob, Bash

**Used By**: /implement (--create-pr), /orchestrate (workflow PRs)

**Definition**: [.claude/agents/github-specialist.md](../agents/github-specialist.md)

---

### metrics-specialist
**Purpose**: Performance analysis and optimization recommendations

**Capabilities**:
- Analyze metrics from .claude/data/metrics/
- Identify bottlenecks
- Statistical analysis
- Optimization suggestions

**Allowed Tools**: Read, Bash, Grep

**Used By**: Custom performance analysis commands (future)

**Definition**: [.claude/agents/metrics-specialist.md](../agents/metrics-specialist.md)

---

### plan-architect
**Purpose**: Phased implementation plan generation

**Capabilities**:
- Create structured plans from research
- /implement compatibility
- Generate specs/plans/NNN_*.md files

**Allowed Tools**: Read, Write, Grep, Glob, WebSearch

**Used By**: /plan, /orchestrate (planning phase)

**Definition**: [.claude/agents/plan-architect.md](../agents/plan-architect.md)

---

### research-specialist
**Purpose**: Read-only research and codebase analysis

**Capabilities**:
- Codebase pattern discovery
- Best practices research
- Alternative approaches investigation
- Concise summaries (max 150-200 words)

**Allowed Tools**: Read, Grep, Glob, WebSearch, WebFetch

**Used By**: /orchestrate (research phase), /plan (optional), /report (optional)

**Definition**: [.claude/agents/research-specialist.md](../agents/research-specialist.md)

---

### test-specialist
**Purpose**: Test execution and failure analysis

**Capabilities**:
- Run tests across multiple frameworks
- Analyze test failures
- Coverage reporting
- Multi-framework support (Jest, pytest, Neovim tests, etc.)

**Allowed Tools**: Bash, Read, Grep

**Used By**: /test (optional), /test-all (optional), /orchestrate (validation)

**Definition**: [.claude/agents/test-specialist.md](../agents/test-specialist.md)

---

## Tool Access Matrix

Quick reference for which tools each agent can use:

| Agent | Read | Write | Edit | Bash | Grep | Glob | TodoWrite | WebSearch | WebFetch |
|-------|------|-------|------|------|------|------|-----------|-----------|----------|
| code-reviewer | ✓ | | | ✓ | ✓ | ✓ | | | |
| code-writer | ✓ | ✓ | ✓ | ✓ | | | ✓ | | |
| collapse_specialist | ✓ | | | | ✓ | ✓ | | | |
| complexity_estimator | ✓ | | | | ✓ | ✓ | | | |
| debug-specialist | ✓ | | | ✓ | ✓ | ✓ | | ✓ | |
| doc-converter | ✓ | ✓ | | ✓ | | | | | |
| doc-converter-update | ✓ | ✓ | ✓ | ✓ | | | | | |
| doc-converter-usage | ✓ | | | ✓ | | | | | |
| doc-writer | ✓ | ✓ | ✓ | | ✓ | ✓ | | | |
| expansion_specialist | ✓ | | | | ✓ | ✓ | | | |
| github-specialist | ✓ | | | ✓ | ✓ | ✓ | | | |
| metrics-specialist | ✓ | | | ✓ | ✓ | | | | |
| plan-architect | ✓ | ✓ | | | ✓ | ✓ | | ✓ | |
| research-specialist | ✓ | | | | ✓ | ✓ | | ✓ | ✓ |
| test-specialist | ✓ | | | ✓ | ✓ | | | | |

## Agent Selection Guidelines

**Choose based on primary task**:
- **Research/Analysis**: research-specialist (read-only investigation)
- **Code Generation**: code-writer (write and modify code)
- **Testing**: test-specialist (run tests and analyze failures)
- **Planning**: plan-architect (create implementation plans)
- **Documentation**: doc-writer (maintain docs)
- **Code Review**: code-reviewer (standards compliance)
- **Debugging**: debug-specialist (root cause analysis)
- **Performance**: metrics-specialist (analyze performance data)
- **GitHub Operations**: github-specialist (PRs, issues, CI/CD)
- **Complexity Analysis**: complexity_estimator (expansion/collapse decisions)
- **Plan Expansion**: expansion_specialist (phase expansion analysis)
- **Plan Collapse**: collapse_specialist (phase collapse analysis)
- **Document Conversion**: doc-converter (format conversion)

**Tool Restrictions**: Agents can ONLY use tools listed in their allowed-tools. Attempting to use unlisted tools will result in permission errors.

**Invocation Pattern**: Always use `general-purpose` agent type with behavioral injection. See [Using Agents](../guides/agent-development-guide.md) for complete pattern.

## Context Preservation Requirements

When using agents in multi-agent workflows, follow these context preservation patterns to minimize context window consumption:

### Standards 6-8: Context Efficiency

**Standard 6: Metadata-Only Passing** - Pass artifact references (path + 50-word summary) instead of full content between agents. Achieves 99% context reduction.

**Standard 7: Forward Message Pattern** - Pass subagent responses directly to next phase without re-summarization. Eliminates paraphrasing overhead (200-300 tokens per agent).

**Standard 8: Context Pruning** - Prune full content after metadata extraction. Retain only artifact paths and metadata. Achieves 80-90% reduction in accumulated context.

### Utilities

- `extract_report_metadata()` - Extract title + 50-word summary from research reports (`.claude/lib/metadata-extraction.sh`)
- `extract_plan_metadata()` - Extract complexity + phase count from implementation plans
- `forward_message()` - Extract handoff context from subagent output without paraphrasing
- `prune_subagent_output()` - Remove full output after metadata extraction (`.claude/lib/context-pruning.sh`)

### Target

Maintain <30% context usage throughout multi-agent workflows through aggressive metadata extraction and pruning.

**See Also**: [Command Architecture Standards](command_architecture_standards.md#context-preservation-standards) for complete details on Standards 6-8.

## Quick Invocation Template

```yaml
Task {
  subagent_type: "general-purpose"
  description: "[concise task description] using [agent-name] protocol"
  prompt: "
    Read and follow the behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/[agent-name].md

    You are acting as a [Agent Name] with the tools and constraints
    defined in that file.

    [Task Type]: [Specific task]

    Context:
    - [Key context 1]
    - [Key context 2]
    - Project Standards: CLAUDE.md

    Requirements:
    - [Requirement 1]
    - [Requirement 2]

    Output:
    - [Expected output description]
  "
}
```

## Related Documentation

- [Using Agents](../guides/agent-development-guide.md) - Comprehensive agent integration guide with invocation patterns
- [Creating Agents](../guides/agent-development-guide.md) - Guide for developing custom agents
- [Command Patterns](../guides/command-patterns.md) - Command development best practices
- [Orchestration Guide](../workflows/orchestration-guide.md) - Multi-agent workflows
