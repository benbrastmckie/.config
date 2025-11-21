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

For command architecture standards and agent invocation patterns, see [Command Architecture Standards](../architecture/overview.md).

## Agent Directory

### claude-md-analyzer
**Purpose**: Analyzes CLAUDE.md structure and identifies optimization opportunities using existing library functions

**Capabilities**:
- Parse CLAUDE.md section boundaries using optimize-claude-md.sh library
- Identify bloated sections (>80 lines with balanced threshold)
- Detect metadata gaps ([Used by: ...] tags)
- Suggest integration points for .claude/docs/ extractions
- Generate structured analysis reports

**Allowed Tools**: Read, Write, Grep, Bash

**Used By**: /optimize-claude (research stage)

**Definition**: [.claude/agents/claude-md-analyzer.md](../../agents/claude-md-analyzer.md)

---

### cleanup-plan-architect
**Purpose**: Synthesizes research reports and generates CLAUDE.md optimization implementation plans

**Capabilities**:
- Read and synthesize multiple research reports
- Match bloated sections to appropriate .claude/docs/ locations
- Generate /implement-compatible optimization plans
- Include backup and rollback procedures
- Create phased extraction strategies

**Allowed Tools**: Read, Write, Grep, Bash

**Used By**: /optimize-claude (planning stage)

**Definition**: [.claude/agents/cleanup-plan-architect.md](../../agents/cleanup-plan-architect.md)

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

**Definition**: [.claude/agents/complexity_estimator.md](../../agents/complexity-estimator.md)

---

### debug-specialist
**Purpose**: Root cause analysis and diagnostic investigations

**Capabilities**:
- Issue investigation with evidence gathering
- Solution proposal with multiple options
- Debug report generation

**Allowed Tools**: Read, Bash, Grep, Glob, WebSearch

**Used By**: /debug, /orchestrate (debugging loop)

**Definition**: [.claude/agents/debug-specialist.md](../../agents/debug-specialist.md)

---

### debug-analyst
**Purpose**: Parallel root cause analysis for complex bugs with multiple potential causes

**Capabilities**:
- Hypothesis testing across multiple potential root causes
- Log analysis and code inspection
- Structured findings with proposed fixes
- Parallel investigation coordination

**Allowed Tools**: Read, Bash, Grep, Glob

**Used By**: /debug (parallel investigations)

**Definition**: [.claude/agents/debug-analyst.md](../../agents/debug-analyst.md)

---

### errors-analyst
**Purpose**: Error log analysis, pattern detection, and error report generation

**Capabilities**:
- Parse JSONL error log format with structured field extraction
- Group errors by type, command, and time patterns
- Calculate frequency statistics and identify top error patterns
- Generate structured markdown reports with metadata, findings, and recommendations
- Context-efficient analysis using Haiku model (1000-2200 token budget per report)

**Model**: claude-3-5-haiku-20241022

**Allowed Tools**: Read, Write, Grep, Glob, Bash

**Used By**: /errors (default report generation mode)

**Definition**: [.claude/agents/errors-analyst.md](../../agents/errors-analyst.md)

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

**Definition**: [.claude/agents/doc-converter.md](../../agents/doc-converter.md)

---

### docs-structure-analyzer
**Purpose**: Analyzes .claude/docs/ organization and identifies integration opportunities for CLAUDE.md extractions

**Capabilities**:
- Discover .claude/docs/ directory structure
- Identify existing documentation categories (concepts/, guides/, reference/)
- Find natural integration points for CLAUDE.md extractions
- Detect gaps in documentation coverage
- Identify overlapping or duplicate documentation
- Generate structured analysis reports

**Allowed Tools**: Read, Write, Grep, Glob, Bash

**Used By**: /optimize-claude (research stage)

**Definition**: [.claude/agents/docs-structure-analyzer.md](../../agents/docs-structure-analyzer.md)

---

### docs-accuracy-analyzer
**Purpose**: Semantic documentation quality analysis for accuracy and timeliness

**Capabilities**:
- Accuracy checking against codebase reality
- Consistency validation across documentation
- Timeliness assessment (outdated claims detection)
- Semantic analysis for misleading or incorrect information
- Generate structured quality reports

**Allowed Tools**: Read, Grep, Glob, Bash

**Used By**: /research (documentation quality reports), /setup --analyze

**Definition**: [.claude/agents/docs-accuracy-analyzer.md](../../agents/docs-accuracy-analyzer.md)

---

### docs-bloat-analyzer
**Purpose**: CLAUDE.md structure analysis and bloat detection for optimization planning

**Capabilities**:
- File size analysis and bloat scoring
- Extraction recommendations for oversized sections
- Risk assessment for potential merges
- Integration point identification for .claude/docs/
- Generate structured bloat reports

**Allowed Tools**: Read, Grep, Glob, Bash

**Used By**: /setup --analyze, /optimize-claude

**Definition**: [.claude/agents/docs-bloat-analyzer.md](../../agents/docs-bloat-analyzer.md)

---

### doc-converter-update
**Purpose**: Updates existing converted documents with new content

**Capabilities**:
- Incremental updates to converted documents
- Change tracking and version management
- Preserves formatting during updates

**Allowed Tools**: Read, Write, Edit, Bash

**Used By**: /convert-docs (update mode)

**Definition**: [.claude/agents/doc-converter-update.md](../../agents/doc-converter.md)

---

### implementer-coordinator
**Purpose**: Multi-implementer coordination for parallel wave-based execution

**Capabilities**:
- Dependency analysis across implementation tasks
- Task distribution to parallel implementers
- Merge coordination and conflict resolution
- Wave progression management
- Metadata consolidation from implementers

**Allowed Tools**: Read, Write, Grep, Glob, Bash, Task

**Used By**: /build (wave-based implementation)

**Definition**: [.claude/agents/implementer-coordinator.md](../../agents/implementer-coordinator.md)

---

### plan-architect
**Purpose**: Phased implementation plan generation

**Capabilities**:
- Create structured plans from research
- /implement compatibility
- Generate specs/plans/NNN_*.md files

**Allowed Tools**: Read, Write, Grep, Glob, WebSearch

**Used By**: /plan, /orchestrate (planning phase)

**Definition**: [.claude/agents/plan-architect.md](../../agents/plan-architect.md)

---

### repair-analyst
**Purpose**: Error log analysis and root cause pattern detection

**Capabilities**:
- Read and parse error logs from .claude/data/logs/errors.jsonl
- Group errors by type, command, and root cause using inline jq analysis
- Calculate frequencies and distributions
- Identify correlated errors and systemic issues
- Create structured error analysis reports with recommendations

**Allowed Tools**: Read, Write, Grep, Glob, Bash

**Used By**: /repair (error analysis phase)

**Definition**: [.claude/agents/repair-analyst.md](../../agents/repair-analyst.md)

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

**Definition**: [.claude/agents/research-specialist.md](../../agents/research-specialist.md)

---

### research-sub-supervisor
**Purpose**: Hierarchical research coordination managing 2-4 parallel research agents

**Capabilities**:
- Coordinate 2-4 specialized research agents per domain
- Metadata consolidation from multiple researchers
- Topic decomposition for parallel research
- Report aggregation and synthesis
- Recursive supervision for complex topics

**Allowed Tools**: Read, Write, Grep, Glob, Task

**Used By**: /research (complex topics), /orchestrate (research phase)

**Definition**: [.claude/agents/research-sub-supervisor.md](../../agents/research-sub-supervisor.md)

---

### spec-updater
**Purpose**: Artifact lifecycle management in topic-based directories with gitignore compliance

**Capabilities**:
- Create and manage topic-based directory structures (specs/{NNN_topic}/)
- File creation with proper subdirectory placement (plans/, reports/, summaries/, debug/)
- Gitignore compliance enforcement (plans gitignored, debug reports committed)
- Cross-reference maintenance across artifacts
- Metadata extraction and propagation

**Allowed Tools**: Read, Write, Edit, Grep, Glob, Bash

**Used By**: All orchestration commands (/orchestrate, /coordinate, /supervise)

**Definition**: [.claude/agents/spec-updater.md](../../agents/spec-updater.md)

---

## Tool Access Matrix

Quick reference for which tools each agent can use:

| Agent | Read | Write | Edit | Bash | Grep | Glob | TodoWrite | WebSearch | WebFetch |
|-------|------|-------|------|------|------|------|-----------|-----------|----------|
| claude-md-analyzer | ✓ | ✓ | | ✓ | ✓ | | | | |
| cleanup-plan-architect | ✓ | ✓ | | ✓ | ✓ | | | | |
| complexity_estimator | ✓ | | | | ✓ | ✓ | | | |
| debug-specialist | ✓ | | | ✓ | ✓ | ✓ | | ✓ | |
| doc-converter | ✓ | ✓ | | ✓ | | | | | |
| docs-structure-analyzer | ✓ | ✓ | | ✓ | ✓ | ✓ | | | |
| implementer-coordinator | ✓ | ✓ | | ✓ | ✓ | ✓ | | | |
| plan-architect | ✓ | ✓ | | | ✓ | ✓ | | ✓ | |
| research-specialist | ✓ | | | | ✓ | ✓ | | ✓ | ✓ |
| research-sub-supervisor | ✓ | ✓ | | | ✓ | ✓ | | | |
| spec-updater | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | | | |

## Agent Selection Guidelines

**Choose based on primary task**:
- **Research/Analysis**: research-specialist (read-only investigation)
- **Planning**: plan-architect (create implementation plans)
- **Debugging**: debug-specialist (root cause analysis)
- **Complexity Analysis**: complexity_estimator (expansion/collapse decisions)
- **Document Conversion**: doc-converter (format conversion)
- **CLAUDE.md Analysis**: claude-md-analyzer (analyze CLAUDE.md structure and bloat)
- **Docs Structure Analysis**: docs-structure-analyzer (analyze .claude/docs/ organization)
- **Optimization Planning**: cleanup-plan-architect (generate CLAUDE.md optimization plans)
- **Wave-Based Implementation**: implementer-coordinator (parallel phase execution)

**Tool Restrictions**: Agents can ONLY use tools listed in their allowed-tools. Attempting to use unlisted tools will result in permission errors.

**Invocation Pattern**: Always use `general-purpose` agent type with behavioral injection. See [Using Agents](../guides/development/agent-development/agent-development-fundamentals.md) for complete pattern.

## Context Preservation Requirements

When using agents in multi-agent workflows, follow these context preservation patterns to minimize context window consumption:

### Standards 6-8: Context Efficiency

**Standard 6: Metadata-Only Passing** - Pass artifact references (path + 50-word summary) instead of full content between agents. Achieves 99% context reduction.

**Standard 7: Forward Message Pattern** - Pass subagent responses directly to next phase without re-summarization. Eliminates paraphrasing overhead (200-300 tokens per agent).

**Standard 8: Context Pruning** - Prune full content after metadata extraction. Retain only artifact paths and metadata. Achieves 80-90% reduction in accumulated context.

### Utilities

- `extract_report_metadata()` - Extract title + 50-word summary from research reports (`.claude/lib/workflow/metadata-extraction.sh`)
- `extract_plan_metadata()` - Extract complexity + phase count from implementation plans
- `forward_message()` - Extract handoff context from subagent output without paraphrasing
- `prune_subagent_output()` - Remove full output after metadata extraction (`.claude/lib/workflow/context-pruning.sh`)

### Target

Maintain <30% context usage throughout multi-agent workflows through aggressive metadata extraction and pruning.

**See Also**: [Command Architecture Standards](../architecture/overview.md#context-preservation-standards) for complete details on Standards 6-8.

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

- [Using Agents](../guides/development/agent-development/agent-development-fundamentals.md) - Comprehensive agent integration guide with invocation patterns
- [Creating Agents](../guides/development/agent-development/agent-development-fundamentals.md) - Guide for developing custom agents
- [Command Patterns](../guides/patterns/command-patterns/command-patterns-overview.md) - Command development best practices
- [Orchestration Guide](../workflows/orchestration-guide.md) - Multi-agent workflows
