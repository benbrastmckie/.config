# Command Quick Reference

Quick lookup guide for all Claude Code slash commands. For comprehensive command development guidance, see [Creating Commands](../guides/development/command-development/command-development-fundamentals.md).

## About This Reference

This reference provides quick access to all available commands with their purpose, usage, and relationships. Commands are organized alphabetically and grouped by type and agent usage for easy navigation.

## Architectural Context

Commands are **AI execution scripts**, not traditional workflow automation. They contain executable instructions, agent invocation logic, and decision points that Claude interprets directly. Commands follow 11 architectural standards (Standards 1-11) covering inline execution requirements, context preservation, and lean design principles.

See [Command Architecture Standards](../architecture/overview.md) for complete standards documentation.

---

## Command Index (Alphabetical)

### Active Commands
- [/analyze](#analyze)
- [/build](#build)
- [/collapse](#collapse)
- [/convert-docs](#convert-docs)
- [/document](#document)
- [/errors](#errors)
- [/example-with-agent](#example-with-agent)
- [/expand](#expand)
- [/list](#list)
- [/optimize-claude](#optimize-claude)
- [/plan](#plan)
- [/plan-from-template](#plan-from-template)
- [/plan-wizard](#plan-wizard)
- [/refactor](#refactor)
- [/repair](#repair)
- [/report](#report)
- [/research](#research)
- [/revise](#revise)
- [/setup](#setup)
- [/test](#test)
- [/test-all](#test-all)
- [/todo](#todo)

### Archived Commands
- [/coordinate](#coordinate-archived)
- [/debug](#debug-archived)
- [/implement](#implement-archived)
- [/update](#update-archived)

---

## Command Descriptions

### /analyze
**Purpose**: Analyze system performance metrics and patterns

**Usage**: `/analyze [type] [search-pattern]`

**Type**: utility

**Arguments**:
- `type` (optional): `agents`, `patterns`, or `all`
- `search-pattern` (optional): Filter results

**Agents Used**: None (direct analysis)

**Output**: Console analysis report with rankings and recommendations

**See**: [analyze.md](../../commands/analyze.md)

---

### /build
**Purpose**: Build-from-plan workflow - Implementation, testing, debug, and documentation phases

**Usage**: `/build [plan-file] [starting-phase] [--dry-run]`

**Type**: orchestrator

**Arguments**:
- `plan-file` (optional): Path to implementation plan (auto-detects if omitted)
- `starting-phase` (optional): Phase number to start from (default: 1)
- `--dry-run`: Preview execution without running

**Agents Used**: implementer-coordinator, debug-analyst

**Output**: Implemented features with commits, test results, debug analysis or documentation

**Workflow**: `implement → test → [debug OR document] → complete`

**Automatically updates TODO.md**: Yes (at START when marking plan IN PROGRESS, and at COMPLETION when marking plan COMPLETE)

**See**: [build.md](../../commands/build.md)

---

### /collapse
**Purpose**: Merge expanded phase/stage back into parent plan (structural simplification)

**Usage**: `/collapse [phase|stage] <plan-path> [phase-num] [stage-num]`

**Type**: workflow

**Arguments**:
- `phase`: Collapse Level 1 → Level 0
- `stage`: Collapse Level 2 → Level 1
- `plan-path`: Path to plan or plan directory
- `phase-num`: Phase number (for phase collapse)
- `stage-num`: Stage number (for stage collapse)

**Agents Used**: None

**Output**: Merged content in parent file, directory cleanup

**See**: [collapse.md](../../commands/collapse.md)

---

### /convert-docs
**Purpose**: Convert between Markdown, Word (DOCX), and PDF formats bidirectionally

**Usage**: `/convert-docs <input-directory> [output-directory] [--use-agent]`

**Type**: utility

**Arguments**:
- `input-directory`: Directory containing documents to convert
- `output-directory` (optional): Where to place converted files
- `--use-agent`: Use doc-converter agent for assistance

**Agents Used**: doc-converter (optional)

**Output**: Converted document files

**See**: [convert-docs.md](../../commands/convert-docs.md)

---

### /coordinate
**Status**: ARCHIVED - Use `/build`, `/plan`, `/research`, `/debug`, or `/revise` instead

**Purpose**: Clean multi-agent workflow orchestration with wave-based parallel implementation

**Migration**: This command has been archived and its functionality split into dedicated commands:
- `/build` - For implementation workflows
- `/plan` - For research and planning workflows
- `/research` - For research-only workflows
- `/debug` - For debugging workflows
- `/revise` - For plan revision workflows

**Archive Location**: `.claude/archive/coordinate/commands/coordinate.md`

---

### /debug
**Status**: ARCHIVED - Use `/debug` instead

**Purpose**: Investigate issues and create diagnostic reports without code changes

**Migration**: This command has been archived. Use `/debug` for bug fixing workflows.

**Archive Location**: `.claude/archive/legacy-workflow-commands/commands/debug.md`

---

### /document
**Purpose**: Update documentation based on recent code changes

**Usage**: `/document [change-description] [scope]`

**Type**: support

**Arguments**:
- `change-description` (optional): What changed
- `scope` (optional): Specific files/directories to document

**Output**: Updated README files and documentation

**See Also**:
- [/document Command Guide](../guides/commands/document-command-guide.md) - Comprehensive usage, standards compliance, timeless writing
- [document.md](../../commands/document.md) - Executable command file

---

### /errors
**Purpose**: Generate error analysis reports via errors-analyst agent, or query error logs directly

**Usage**: `/errors [options]`

**Type**: utility

**Modes**:
- **Default Mode** (no `--query` flag): Generate structured error analysis report via errors-analyst agent
- **Query Mode** (`--query` flag): Display error logs directly (backward compatible)

**Arguments**:
- `--command <cmd>` (optional): Filter by command name (e.g., `/build`, `/plan`)
- `--since <time>` (optional): Filter errors since timestamp (ISO 8601 format)
- `--type <type>` (optional): Filter by error type (state_error, validation_error, agent_error, etc.)
- `--workflow-id <id>` (optional): Filter by workflow ID
- `--limit <N>` (optional): Limit results (default: 10 for query mode, all for report mode)
- `--log-file <path>` (optional): Log file path (default: .claude/data/logs/errors.jsonl)
- `--query` (optional): Use query mode (legacy behavior)
- `--summary` (optional): Show error summary (query mode only)
- `--raw` (optional): Output raw JSONL entries (query mode only)

**Agents Used**: errors-analyst (Haiku model for context-efficient analysis)

**Output**:
- **Report Mode**: Error analysis report in `.claude/specs/{NNN_error_analysis}/reports/001_error_report.md`
- **Query Mode**: Formatted error log entries with context and timestamps

**See Also**:
- [/errors Command Guide](../guides/commands/errors-command-guide.md) - Comprehensive usage, report generation, query patterns
- [errors.md](../../commands/errors.md) - Executable command file
- [errors-analyst Agent](agent-reference.md#errors-analyst) - Error analysis agent reference

---

### /example-with-agent
**Purpose**: Template showing proper agent invocation via registry

**Usage**: `/example-with-agent`

**Type**: utility

**Arguments**: None

**Agents Used**: example-agent (template)

**Output**: Example demonstration

**See**: [example-with-agent.md](../../commands/example-with-agent.md)

---

### /expand
**Purpose**: Extract phase/stage to separate file (structural organization)

**Usage**: `/expand [phase|stage] <plan-path> [phase-num] [stage-num]`

**Type**: workflow

**Arguments**:
- `phase`: Expand Level 0 → Level 1
- `stage`: Expand Level 1 → Level 2
- `plan-path`: Path to plan file
- `phase-num`: Phase number to expand
- `stage-num`: Stage number to expand

**Agents Used**: None

**Output**: Extracted phase/stage file, updated main plan

**See**: [expand.md](../../commands/expand.md)

---

### /debug
**Purpose**: Debug-focused workflow - Root cause analysis and bug fixing

**Usage**: `/debug <issue-description> [--file <path>] [--complexity 1-4]`

**Type**: orchestrator

**Arguments**:
- `issue-description` (required): Description of issue to investigate
- `--file` (optional): Path to file containing long prompt (archived to specs/NNN_topic/prompts/)
- `--complexity` (optional): Research depth 1-4 (default: 2)

**Agents Used**: research-specialist, plan-architect, debug-analyst

**Output**: Debug research reports, debug strategy plan, root cause analysis

**Workflow**: `research → plan (debug strategy) → debug → complete`

**Automatically updates TODO.md**: Yes (after debug report creation)

**See**: [debug.md](../../commands/debug.md)

---

### /implement
**Status**: ARCHIVED - Use `/build` instead

**Purpose**: Execute implementation plans with automated testing and commits

**Migration**: This command has been archived. Use `/build` for plan implementation workflows.

**Archive Location**: `.claude/archive/legacy-workflow-commands/commands/implement.md`

---

### /list
**Purpose**: List implementation artifacts (plans, reports, summaries) with metadata

**Usage**: `/list [plans|reports|summaries|all] [--recent N] [--incomplete] [search-pattern]`

**Type**: utility

**Arguments**:
- `plans|reports|summaries|all`: Artifact type to list
- `--recent N`: Show only N most recent
- `--incomplete`: Show only incomplete plans
- `search-pattern`: Filter by pattern

**Agents Used**: None

**Output**: Formatted list with metadata

**See**: [list.md](../../commands/list.md)

---

### /optimize-claude
**Purpose**: Analyze CLAUDE.md and .claude/docs/ structure to generate optimization plan for documentation bloat reduction and quality improvement

**Usage**: `/optimize-claude "[description] [--threshold <profile>] [--dry-run] [--file <report>]"`

**Type**: orchestrator

**Arguments**:
- `description` (optional): Custom description of optimization focus (default: "Optimize CLAUDE.md structure and documentation")
- `--threshold <profile>` (optional): Bloat detection threshold profile - aggressive (50/30 lines), balanced (80/50 lines), conservative (120/80 lines) (default: balanced)
- `--aggressive`: Shorthand for --threshold aggressive
- `--balanced`: Shorthand for --threshold balanced (default)
- `--conservative`: Shorthand for --threshold conservative
- `--dry-run` (optional): Preview workflow stages without executing agents
- `--file <path>` (optional, repeatable): Additional report file for context-aware analysis

**Agents Used**:
- `claude-md-analyzer` (Haiku 4.5): Analyze CLAUDE.md structure and identify bloated sections
- `docs-structure-analyzer` (Haiku 4.5): Analyze .claude/docs/ organization and identify integration opportunities
- `docs-bloat-analyzer` (Opus 4.5): Perform semantic bloat analysis and assess extraction risks using soft guidance model
- `docs-accuracy-analyzer` (Opus 4.5): Evaluate documentation quality across 6 dimensions (accuracy, completeness, consistency, timeliness, usability, clarity)
- `cleanup-plan-architect` (Sonnet 4.5): Synthesize research reports and generate implementation plan with advisory size guidance

**Output**: Optimization plan with CLAUDE.md extraction phases, bloat prevention tasks (soft guidance, not hard blockers), accuracy fixes, and quality improvements

**Workflow**: `setup → research (parallel: claude-md + docs-structure) → analysis (parallel: bloat + accuracy) → planning (cleanup-plan-architect) → display`

**Automatically updates TODO.md**: No (manual plan tracking via /build)

**See**: [optimize-claude.md](../../commands/optimize-claude.md)

---

### /plan
**Status**: ARCHIVED - Use `/plan` instead

**Purpose**: Create detailed implementation plans following project standards

**Migration**: This command has been archived. Use `/plan` for planning workflows that include research.

**Archive Location**: `.claude/archive/legacy-workflow-commands/commands/plan.md`

---

### /plan-from-template
**Purpose**: Generate implementation plans from reusable templates

**Usage**: `/plan-from-template <template-name>`

**Type**: support

**Arguments**:
- `template-name`: Name of template (crud-feature, api-endpoint, refactoring, etc.)

**Agents Used**: None (template-based generation)

**Output**: Implementation plan from template in `specs/plans/NNN_plan_name.md`

**See**: [plan-from-template.md](../../commands/plan-from-template.md)

---

### /plan-wizard
**Purpose**: Interactive wizard for guided plan creation with research integration

**Usage**: `/plan-wizard`

**Type**: support

**Arguments**: None (interactive prompts)

**Agents Used**: research-specialist (optional, for research phase)

**Output**: Implementation plan in `specs/plans/NNN_plan_name.md`

**See**: [plan-wizard.md](../../commands/plan-wizard.md)

---

### /refactor
**Purpose**: Analyze code for refactoring opportunities based on project standards

**Usage**: `/refactor [file/directory/module] [specific-concerns]`

**Type**: support

**Arguments**:
- `file/directory/module` (optional): Target for refactoring analysis
- `specific-concerns` (optional): Specific areas to focus on

**Agents Used**: code-analyzer

**Output**: Refactoring report in `specs/reports/refactoring/NNN_analysis.md`

**See**: [refactor.md](../../commands/refactor.md)

---

### /repair
**Purpose**: Research error patterns and create implementation plan to fix them

**Usage**: `/repair [--since TIME] [--type TYPE] [--command CMD] [--severity LEVEL] [--complexity 1-4]`

**Type**: orchestrator

**Arguments**:
- `--since` (optional): Filter errors since timestamp (e.g., "1h", "2025-01-01")
- `--type` (optional): Filter by error type (state_error, validation_error, agent_error, etc.)
- `--command` (optional): Filter by command name (e.g., `/build`, `/plan`)
- `--severity` (optional): Filter by severity level
- `--complexity` (optional): Research depth 1-4 (default: 2)

**Agents Used**: research-specialist, research-sub-supervisor, plan-architect

**Output**: Research reports + repair plan

**Workflow**: `research (error analysis) → plan (repair strategy) → complete`

**Automatically updates TODO.md**: Yes (after repair plan creation)

**See**: [repair.md](../../commands/repair.md)

---

### /report
**Purpose**: Research topics and create comprehensive reports

**Usage**: `/report <topic-or-question>`

**Type**: primary

**Arguments**:
- `topic-or-question`: What to research

**Agents Used**: research-specialist

**Output**: Research report in `specs/reports/{topic}/NNN_report_name.md`

**Dependent Commands**: plan

---

### /plan
**Purpose**: Research and create new implementation plan workflow

**Usage**: `/plan <feature-description> [--file <path>] [--complexity 1-4]`

**Type**: orchestrator

**Arguments**:
- `feature-description` (required): Feature to research and plan
- `--file` (optional): Path to file containing long prompt (archived to specs/NNN_topic/prompts/)
- `--complexity` (optional): Research depth 1-4 (default: 3)

**Agents Used**: research-specialist, research-sub-supervisor, plan-architect

**Output**: Research reports + implementation plan

**Workflow**: `research → plan → complete`

**Automatically updates TODO.md**: Yes (after new plan creation)

**See**: [plan.md](../../commands/plan.md)

---

### /research
**Purpose**: Research-only workflow - Creates comprehensive research reports without planning or implementation

**Usage**: `/research <workflow-description> [--file <path>] [--complexity 1-4]`

**Type**: orchestrator

**Arguments**:
- `workflow-description` (required): Topic to research
- `--file` (optional): Path to file containing long prompt (archived to specs/NNN_topic/prompts/)
- `--complexity` (optional): Research depth 1-4 (default: 2)

**Agents Used**: research-specialist, research-sub-supervisor

**Output**: Research reports only (no plan)

**Workflow**: `research → complete`

**Automatically updates TODO.md**: Yes (after report creation)

**See**: [research.md](../../commands/research.md)

---

### /revise
**Purpose**: Research and revise existing implementation plan workflow

**Usage**: `/revise "revise plan at <plan-path> based on <new-insights>" [--complexity 1-4]`

**Type**: orchestrator

**Arguments**:
- `revision-description` (required): Must include plan path and revision details
- `--complexity` (optional): Research depth 1-4 (default: 2)

**Agents Used**: research-specialist, research-sub-supervisor, plan-architect

**Output**: Research reports + revised plan (with backup)

**Workflow**: `research → plan revision → complete`

**Automatically updates TODO.md**: Yes (after plan modification)

**See**: [revise.md](../../commands/revise.md)

---

### /research
**Status**: ARCHIVED - Use `/research` or `/plan` instead

**Purpose**: Research topics and create comprehensive reports

**Migration**: This command has been archived. Use `/research` for research-only workflows or `/plan` for combined research and planning.

**Archive Location**: `.claude/archive/legacy-workflow-commands/commands/research.md`

---

### /revise
**Status**: ARCHIVED - Use `/revise` instead

**Purpose**: Revise existing plan or report with new requirements (content modification)

**Migration**: This command has been archived. Use `/revise` for plan revision workflows that may require research.

**Archive Location**: `.claude/archive/legacy-workflow-commands/commands/revise.md`

---

### /setup
**Purpose**: Setup or analyze CLAUDE.md with automatic mode detection for initialization and diagnostics

**Usage**: `/setup [project-directory] [--force]`

**Type**: utility

**Arguments**:
- `project-directory` (optional): Target directory (defaults to project root)
- `--force`: Overwrite existing CLAUDE.md without switching to analysis mode

**Modes** (automatic detection):
- **Standard Mode**: Creates CLAUDE.md with auto-detected standards (when file doesn't exist)
- **Analysis Mode**: Validates and analyzes existing CLAUDE.md (automatic when file exists)
- **Force Mode**: Regenerates CLAUDE.md from scratch (with --force flag)

**Related Commands**:
- `/optimize-claude`: For cleanup and enhancement operations

**Agents Used**: None

**Output**: Created CLAUDE.md file or analysis report in `.claude/specs/NNN_*/reports/`

**See**: [setup.md](../../commands/setup.md), [Setup Command Guide](../guides/commands/setup-command-guide.md)

---

### /test
**Purpose**: Test and debug workflow - Execute test suite with coverage loop until quality threshold met

**Usage**: `/test [plan-file] [--file <summary>] [--coverage-threshold=N] [--max-iterations=N]`

**Type**: primary

**Arguments**:
- `plan-file`: Path to implementation plan (optional if using --file)
- `--file <summary>`: Explicit path to implementation summary (auto-discovery if omitted)
- `--coverage-threshold=N`: Coverage percentage threshold (default: 80)
- `--max-iterations=N`: Maximum test iterations for coverage loop (default: 5)

**Agents Used**:
- test-executor: Execute test suite with framework detection and structured reporting
- debug-analyst: Analyze test failures and coverage gaps (conditional, on failure)

**TODO.md Integration**: Automatically updates TODO.md after successful test completion (all tests passed AND coverage threshold met)

**Output**: Test results with coverage metrics, optional debug reports in `.claude/specs/NNN_*/outputs/` and `.claude/specs/NNN_*/debug/`

**See Also**:
- [/test Command Guide](../guides/commands/test-command-guide.md) - Comprehensive usage, multi-framework testing, error analysis
- [test.md](../../commands/test.md) - Executable command file

---

### /test-all
**Purpose**: Run complete test suite for the project

**Usage**: `/test-all [coverage]`

**Type**: primary

**Arguments**:
- `coverage` (optional): Include coverage report

**Agents Used**: None (direct execution)

**Output**: Full test suite results and coverage

**See**: [test-all.md](../../commands/test-all.md)

---

### /todo
**Purpose**: Scan specs directories and update TODO.md with current project status

**Usage**: `/todo [--clean] [--dry-run]`

**Type**: utility

**Arguments**:
- `--clean` (optional): Generate cleanup plan for completed projects
- `--dry-run` (optional): Preview changes without modifying files

**Agents Used**: todo-analyzer (Haiku model for fast batch classification)

**Output**:
- **Default Mode**: Updated `.claude/TODO.md` with current project status
- **Clean Mode**: Cleanup plan for completed projects older than 30 days

**Features**:
- Automatic project discovery via specs directory scanning
- Fast plan status classification using Haiku model
- Hierarchical TODO.md organization (6 sections)
- Artifact linking (reports, summaries as indented bullets)
- Preserves manually curated Backlog section
- Date grouping for Completed section

**See**:
- [TODO Command Guide](../guides/commands/todo-command-guide.md) - Comprehensive usage guide
- [todo.md](../../commands/todo.md) - Executable command file
- [TODO Organization Standards](todo-organization-standards.md) - TODO.md structure standards

---

### /update
**Purpose**: ⚠️ DEPRECATED - Use `/revise` instead

**Usage**: N/A (deprecated)

**Type**: workflow

**Migration**: Use `/revise` for all plan and report modifications

**Reason**: Consolidated into `/revise` to reduce command overlap and confusion

**See**: [Command Selection Guide](../guides/development/command-development/command-development-fundamentals.md)

---

## Commands by Type

### Primary Commands
Core development workflow drivers:
- **/build** - Build-from-plan workflow with testing and documentation
- **/debug** - Debug-focused workflow for root cause analysis
- **/plan** - Research and create implementation plans
- **/research** - Research-only workflow for reports
- **/revise** - Research and revise existing plans
- **/test** - Run project-specific tests
- **/test-all** - Run complete test suite

### Archived Commands
Legacy commands that have been superseded:
- **/coordinate** - ARCHIVED (use /build, /plan, /research, /debug, or /revise)
- **/debug** - ARCHIVED (use /debug)
- **/implement** - ARCHIVED (use /build)
- **/plan** - ARCHIVED (use /plan)
- **/research** - ARCHIVED (use /research or /plan)
- **/revise** - ARCHIVED (use /revise)

### Support Commands
Specialized assistance commands:
- **/document** - Update documentation based on code changes
- **/plan-from-template** - Generate plans from templates
- **/plan-wizard** - Interactive plan creation wizard
- **/refactor** - Analyze code for refactoring opportunities

### Workflow Commands
Execution state and artifact management:
- **/collapse** - Merge expanded phases/stages back to parent
- **/expand** - Extract phases/stages to separate files
- **/update** - DEPRECATED (use /revise)

### Utility Commands
Maintenance and setup commands:
- **/analyze** - System performance metrics and analysis
- **/convert-docs** - Document format conversion
- **/errors** - Query and analyze error logs
- **/example-with-agent** - Agent invocation template
- **/list** - List implementation artifacts
- **/setup** - Configure or update CLAUDE.md
- **/todo** - Scan specs and update TODO.md

---

## Commands by Agent

### research-specialist
Research and codebase analysis:
- **/plan** (research phase)
- **/research** (research phase)
- **/plan-wizard** (optional research phase)
- **/report**

### plan-architect
Structured implementation planning:
- **/plan** (planning phase)
- **/revise** (complex plan changes)
- **/debug** (debug strategy planning)

### debug-analyst
Issue investigation:
- **/debug** (root cause analysis)
- **/build** (conditional debugging)

### doc-converter
Document format conversion:
- **/convert-docs** (optional)

### code-analyzer
Code quality analysis:
- **/refactor**

---

## Related Documentation

- **[Creating Commands](../guides/development/command-development/command-development-fundamentals.md)** - Comprehensive guide for developing commands
- **[Command Patterns](../guides/patterns/command-patterns/command-patterns-overview.md)** - Reusable implementation patterns
- **[Agent Reference](agent-reference.md)** - Quick agent reference (Phase 4)
- **[Command Selection Guide](../guides/development/command-development/command-development-fundamentals.md)** - Decision tree for choosing commands
- **[Commands README](../../commands/README.md)** - Complete command documentation

---

**Notes**:
- Command count: 15 active commands + 6 archived + 1 deprecated
- All commands support CLAUDE.md standards discovery
- Commands can invoke specialized agents for complex tasks
- Progressive plan structure (L0/L1/L2) supported by plan-related commands
- Artifact organization: specs/ (gitignored), debug/ (tracked)
- Archived commands available at `.claude/archive/`
