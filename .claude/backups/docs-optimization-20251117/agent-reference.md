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

### code-reviewer
**Purpose**: Reviews code against project standards and identifies quality issues

**Capabilities**:
- Standards compliance review
- Code quality analysis
- Refactoring opportunity identification
- Review report generation with severity levels

**Allowed Tools**: Read, Grep, Glob, Bash

**Used By**: /refactor, /orchestrate (optional pre-commit)

**Definition**: [.claude/agents/code-reviewer.md](../../agents/code-reviewer.md)

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

**Definition**: [.claude/agents/code-writer.md](../../agents/code-writer.md)

---

### collapse_specialist
**Purpose**: Analyzes expanded plans for collapsing back to parent structure

**Capabilities**:
- Complexity re-analysis for expanded phases/stages
- Collapse recommendations with justification
- Determines if content can be safely merged

**Allowed Tools**: Read, Grep, Glob

**Used By**: /collapse (auto-analysis mode)

**Definition**: [.claude/agents/collapse_specialist.md](../../agents/plan-structure-manager.md)

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

### doc-converter-usage
**Purpose**: Demonstrates document conversion tool usage patterns

**Capabilities**:
- Example conversion workflows
- Common conversion scenarios
- Best practices for document conversion

**Allowed Tools**: Read, Bash

**Used By**: Internal documentation and examples

**Definition**: [.claude/agents/doc-converter-usage.md](../../agents/doc-converter.md)

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

**Definition**: [.claude/agents/doc-writer.md](../../agents/doc-writer.md)

---

### expansion_specialist
**Purpose**: Analyzes phases for expansion into detailed specifications

**Capabilities**:
- Phase complexity analysis
- Expansion recommendations with justification
- Determines when expansion provides value

**Allowed Tools**: Read, Grep, Glob

**Used By**: /expand (auto-analysis mode)

**Definition**: [.claude/agents/expansion_specialist.md](../../agents/plan-structure-manager.md)

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

**Definition**: [.claude/agents/github-specialist.md](../../agents/github-specialist.md)

---

### implementation-executor
**Purpose**: Phase execution coordination during implementation with checkpoint management

**Capabilities**:
- Task execution following implementation plans
- Checkpoint management and state tracking
- Test running and validation
- Git commit creation with structured messages
- Phase completion verification

**Allowed Tools**: Read, Write, Edit, Bash, TodoWrite

**Used By**: /implement (phase execution)

**Definition**: [.claude/agents/implementation-executor.md](../../agents/implementation-executor.md)

---

### implementation-sub-supervisor
**Purpose**: Implementation workflow coordination with parallel implementer management

**Capabilities**:
- Parallel implementer coordination
- Wave-based execution management
- Dependency analysis for task distribution
- Merge coordination across multiple implementers
- Progress tracking and reporting

**Allowed Tools**: Read, Write, Grep, Glob, Bash, Task

**Used By**: /orchestrate (implementation supervision)

**Definition**: [.claude/agents/implementation-sub-supervisor.md](../../agents/implementation-sub-supervisor.md)

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

**Used By**: /coordinate (wave-based implementation)

**Definition**: [.claude/agents/implementer-coordinator.md](../../agents/implementer-coordinator.md)

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

**Definition**: [.claude/agents/metrics-specialist.md](../../agents/metrics-specialist.md)

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

### research-specialist
**Purpose**: Read-only research and codebase analysis

**Capabilities**:
- Codebase pattern discovery
- Best practices research
- Alternative approaches investigation
- Concise summaries (max 150-200 words)

**Allowed Tools**: Read, Grep, Glob, WebSearch, WebFetch

**Used By**: /orchestrate (research phase), /plan (optional), /report (optional)

**Definition**: [.claude/agents/research-specialist.md](../../agents/implementation-researcher.md)

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

### research-synthesizer
**Purpose**: Multi-report consolidation and cross-reference extraction for research synthesis

**Capabilities**:
- Read and synthesize multiple research reports
- Cross-reference extraction across reports
- Finding aggregation and deduplication
- Generate unified research summaries
- Identify contradictions and gaps

**Allowed Tools**: Read, Write, Grep, Glob

**Used By**: /research (final report generation)

**Definition**: [.claude/agents/research-synthesizer.md](../../agents/research-synthesizer.md)

---

### revision-specialist
**Purpose**: Plan revision with auto-mode support for adaptive replanning

**Capabilities**:
- Adaptive replanning based on implementation feedback
- Complexity re-evaluation after discoveries
- Phase expansion/compression recommendations
- Auto-mode integration with /implement
- Maximum 2 replans per phase enforcement

**Allowed Tools**: Read, Write, Edit, Grep, Glob

**Used By**: /revise (manual and --auto-mode), /implement (adaptive planning)

**Definition**: [.claude/agents/revision-specialist.md](../../agents/revision-specialist.md)

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

**Definition**: [.claude/agents/test-specialist.md](../../agents/debug-specialist.md)

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

### testing-sub-supervisor
**Purpose**: Test workflow coordination with multi-framework testing support

**Capabilities**:
- Multi-framework test execution coordination
- Coverage analysis and reporting
- Error categorization and prioritization
- Sequential lifecycle coordination (setup → test → teardown)
- Test failure diagnostics

**Allowed Tools**: Read, Write, Bash, Grep, Glob, Task

**Used By**: /orchestrate (testing phase supervision)

**Definition**: [.claude/agents/testing-sub-supervisor.md](../../agents/testing-sub-supervisor.md)

---

### workflow-classifier
**Purpose**: LLM-based workflow detection and enhanced topic generation with 98%+ accuracy

**Capabilities**:
- Semantic workflow classification (llm-only mode, default)
- Traditional regex-based classification (regex-only mode, offline)
- Enhanced topic generation with detailed descriptions and filename slugs
- Topic number assignment from sequence file
- Workflow scope detection (research-only, research-and-plan, full-implementation, debug-only)

**Allowed Tools**: Read, Write, Bash, Grep

**Used By**: /plan, /orchestrate, /coordinate (workflow type detection)

**Definition**: [.claude/agents/workflow-classifier.md](../../agents/workflow-classifier.md)

---

## Tool Access Matrix

Quick reference for which tools each agent can use:

| Agent | Read | Write | Edit | Bash | Grep | Glob | TodoWrite | WebSearch | WebFetch |
|-------|------|-------|------|------|------|------|-----------|-----------|----------|
| claude-md-analyzer | ✓ | ✓ | | ✓ | ✓ | | | | |
| cleanup-plan-architect | ✓ | ✓ | | ✓ | ✓ | | | | |
| code-reviewer | ✓ | | | ✓ | ✓ | ✓ | | | |
| code-writer | ✓ | ✓ | ✓ | ✓ | | | ✓ | | |
| collapse_specialist | ✓ | | | | ✓ | ✓ | | | |
| complexity_estimator | ✓ | | | | ✓ | ✓ | | | |
| debug-specialist | ✓ | | | ✓ | ✓ | ✓ | | ✓ | |
| doc-converter | ✓ | ✓ | | ✓ | | | | | |
| doc-converter-update | ✓ | ✓ | ✓ | ✓ | | | | | |
| doc-converter-usage | ✓ | | | ✓ | | | | | |
| docs-structure-analyzer | ✓ | ✓ | | ✓ | ✓ | ✓ | | | |
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
- **CLAUDE.md Analysis**: claude-md-analyzer (analyze CLAUDE.md structure and bloat)
- **Docs Structure Analysis**: docs-structure-analyzer (analyze .claude/docs/ organization)
- **Optimization Planning**: cleanup-plan-architect (generate CLAUDE.md optimization plans)

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
