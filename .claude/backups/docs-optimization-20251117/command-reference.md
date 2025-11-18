# Command Quick Reference

Quick lookup guide for all Claude Code slash commands. For comprehensive command development guidance, see [Creating Commands](../guides/command-development-guide.md).

## About This Reference

This reference provides quick access to all available commands with their purpose, usage, and relationships. Commands are organized alphabetically and grouped by type and agent usage for easy navigation.

## Architectural Context

Commands are **AI execution scripts**, not traditional workflow automation. They contain executable instructions, agent invocation logic, and decision points that Claude interprets directly. Commands follow 11 architectural standards (Standards 1-11) covering inline execution requirements, context preservation, and lean design principles.

See [Command Architecture Standards](command_architecture_standards.md) for complete standards documentation.

---

## Command Index (Alphabetical)

- [/analyze](#analyze)
- [/build](#build) ✨ NEW
- [/collapse](#collapse)
- [/convert-docs](#convert-docs)
- [/coordinate](#coordinate)
- [/debug](#debug) - ARCHIVED
- [/document](#document)
- [/example-with-agent](#example-with-agent)
- [/expand](#expand)
- [/debug](#fix) ✨ NEW
- [/implement](#implement) - ARCHIVED
- [/list](#list)
- [/plan](#plan) - ARCHIVED
- [/plan-from-template](#plan-from-template)
- [/plan-wizard](#plan-wizard)
- [/refactor](#refactor)
- [/report](#report)
- [/plan](#research-plan) ✨ NEW
- [/research](#research-report) ✨ NEW
- [/revise](#research-revise) ✨ NEW
- [/research](#research) - ARCHIVED
- [/revise](#revise) - ARCHIVED
- [/setup](#setup)
- [/test](#test)
- [/test-all](#test-all)
- [/update](#update) ⚠️ DEPRECATED

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

**See**: [build.md](../../commands/build.md), [Workflow Selection Guide](../guides/workflow-type-selection-guide.md)

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
**Purpose**: Clean multi-agent workflow orchestration with wave-based parallel implementation

**Status**: **Production-Ready** ✓ - Stable, tested, recommended for all workflows

**Complexity**: 2,500-3,000 lines (medium, well-optimized)

**Usage**: `/coordinate <workflow-description>`

**Type**: primary

**Arguments**:
- `workflow-description`: Natural language description of workflow to execute

**Workflow Scope Detection**:
Automatically detects workflow type and executes appropriate phases:
- **research-only**: Phases 0-1 (keywords: "research [topic]" without "plan" or "implement")
- **research-and-plan**: Phases 0-2 (keywords: "research...to create plan", most common)
- **full-implementation**: Phases 0-4, 6 (keywords: "implement", "build", "add feature")
- **debug-only**: Phases 0, 1, 5 (keywords: "fix [bug]", "debug [issue]")

**Key Features**:
- **Wave-Based Execution**: 40-60% time savings through parallel implementation of independent phases
- **Fail-Fast Error Handling**: Clear diagnostics, single execution path, no retries
- **Context Reduction**: <30% context usage via metadata extraction and aggressive pruning
- **Checkpoint Resume**: Auto-resume from phase boundaries after interruption
- **Production-Ready**: Stable, reliable, recommended default orchestration command

**Agents Used**:
- research-specialist (Phase 1)
- plan-architect (Phase 2)
- implementer-coordinator, implementation-executor (Phase 3)
- debug-analyst (Phase 5, conditional)

**Output**:
- Research reports (specs/reports/)
- Implementation plan (specs/plans/)
- Code changes (Phase 3)
- Test results (Phase 4)
- Debug reports (Phase 5, if needed)
- Implementation summary (specs/summaries/)

**Performance**:
- File size: 2,500-3,000 lines (production orchestrator)
- Context usage: <30% throughout workflow
- Time savings: 40-60% (wave-based execution)

**See Also**:
- [Command Selection Guide](../guides/orchestration-best-practices.md#command-selection) - Compare all orchestration commands
- [coordinate.md](../../commands/coordinate.md) - Command documentation

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
- [/document Command Guide](../guides/document-command-guide.md) - Comprehensive usage, standards compliance, timeless writing
- [document.md](../../commands/document.md) - Executable command file

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

**Usage**: `/debug <issue-description> [--complexity 1-4]`

**Type**: orchestrator

**Arguments**:
- `issue-description` (required): Description of issue to investigate
- `--complexity` (optional): Research depth 1-4 (default: 2)

**Agents Used**: research-specialist, plan-architect, debug-analyst

**Output**: Debug research reports, debug strategy plan, root cause analysis

**Workflow**: `research → plan (debug strategy) → debug → complete`

**See**: [fix.md](../../commands/debug.md), [Workflow Selection Guide](../guides/workflow-type-selection-guide.md)

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

**Usage**: `/plan <feature-description> [--complexity 1-4]`

**Type**: orchestrator

**Arguments**:
- `feature-description` (required): Feature to research and plan
- `--complexity` (optional): Research depth 1-4 (default: 3)

**Agents Used**: research-specialist, research-sub-supervisor, plan-architect

**Output**: Research reports + implementation plan

**Workflow**: `research → plan → complete`

**See**: [research-plan.md](../../commands/plan.md), [Workflow Selection Guide](../guides/workflow-type-selection-guide.md)

---

### /research
**Purpose**: Research-only workflow - Creates comprehensive research reports without planning or implementation

**Usage**: `/research <workflow-description> [--complexity 1-4]`

**Type**: orchestrator

**Arguments**:
- `workflow-description` (required): Topic to research
- `--complexity` (optional): Research depth 1-4 (default: 2)

**Agents Used**: research-specialist, research-sub-supervisor

**Output**: Research reports only (no plan)

**Workflow**: `research → complete`

**See**: [research-report.md](../../commands/research.md), [Workflow Selection Guide](../guides/workflow-type-selection-guide.md)

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

**See**: [research-revise.md](../../commands/revise.md), [Workflow Selection Guide](../guides/workflow-type-selection-guide.md)

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
**Purpose**: Setup or improve CLAUDE.md with smart extraction and optimization

**Usage**: `/setup [project-directory] [--cleanup [--dry-run]] [--analyze] [--apply-report <report-path>]`

**Type**: utility

**Arguments**:
- `project-directory` (optional): Target directory
- `--cleanup`: Optimize CLAUDE.md by extracting sections
- `--dry-run`: Preview cleanup without changes
- `--analyze`: Analyze standards completeness
- `--apply-report`: Apply recommendations from report

**Agents Used**: None

**Output**: Created/updated CLAUDE.md file

**See**: [setup.md](../../commands/setup.md)

---

### /test
**Purpose**: Run project-specific tests based on CLAUDE.md protocols

**Usage**: `/test <feature/module/file> [test-type]`

**Type**: primary

**Arguments**:
- `feature/module/file`: Test target
- `test-type` (optional): Type of test to run

**Output**: Test results and analysis

**See Also**:
- [/test Command Guide](../guides/test-command-guide.md) - Comprehensive usage, multi-framework testing, error analysis
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

### /update
**Purpose**: ⚠️ DEPRECATED - Use `/revise` instead

**Usage**: N/A (deprecated)

**Type**: workflow

**Migration**: Use `/revise` for all plan and report modifications

**Reason**: Consolidated into `/revise` to reduce command overlap and confusion

**See**: [Command Selection Guide](../guides/command-development-guide.md)

---

## Commands by Type

### Primary Commands
Core development workflow drivers:
- **/coordinate** - Coordinate multi-agent end-to-end workflows (production orchestrator)
- **/build** - Build-from-plan workflow with testing and documentation
- **/debug** - Debug-focused workflow for root cause analysis
- **/plan** - Research and create implementation plans
- **/research** - Research-only workflow for reports
- **/revise** - Research and revise existing plans
- **/test** - Run project-specific tests
- **/test-all** - Run complete test suite

### Archived Commands
Legacy commands that have been superseded:
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
- **/example-with-agent** - Agent invocation template
- **/list** - List implementation artifacts
- **/setup** - Configure or update CLAUDE.md

---

## Commands by Agent

### research-specialist
Research and codebase analysis:
- **/coordinate** (research phase)
- **/plan-wizard** (optional research phase)
- **/report**

### plan-architect
Structured implementation planning:
- **/coordinate** (planning phase)
- **/plan**
- **/revise** (complex plan changes)

### debug-analyst
Issue investigation:
- **/coordinate** (debugging loop)
- **/debug**

### doc-converter
Document format conversion:
- **/convert-docs** (optional)

### github-specialist
GitHub operations:
- **/coordinate** (PR creation)
- **/build** (PR creation with --create-pr)

### code-analyzer
Code quality analysis:
- **/refactor**

---

## Related Documentation

- **[Creating Commands](../guides/command-development-guide.md)** - Comprehensive guide for developing commands
- **[Command Patterns](../guides/command-patterns.md)** - Reusable implementation patterns
- **[Agent Reference](agent-reference.md)** - Quick agent reference (Phase 4)
- **[Command Selection Guide](../guides/command-development-guide.md)** - Decision tree for choosing commands
- **[Commands README](../../commands/README.md)** - Complete command documentation

---

**Notes**:
- Command count: 15 active commands + 5 archived + 1 deprecated
- All commands support CLAUDE.md standards discovery
- Commands can invoke specialized agents for complex tasks
- Progressive plan structure (L0/L1/L2) supported by plan-related commands
- Artifact organization: specs/ (gitignored), debug/ (tracked)
- Archived commands available at `.claude/archive/legacy-workflow-commands/`
