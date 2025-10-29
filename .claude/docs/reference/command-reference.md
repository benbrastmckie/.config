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
- [/collapse](#collapse)
- [/convert-docs](#convert-docs)
- [/coordinate](#coordinate)
- [/debug](#debug)
- [/document](#document)
- [/example-with-agent](#example-with-agent)
- [/expand](#expand)
- [/implement](#implement)
- [/list](#list)
- [/orchestrate](#orchestrate)
- [/plan](#plan)
- [/plan-from-template](#plan-from-template)
- [/plan-wizard](#plan-wizard)
- [/refactor](#refactor)
- [/report](#report)
- [/revise](#revise)
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

**Agents Used**:
- research-specialist (Phase 1)
- plan-architect (Phase 2)
- implementer-coordinator, implementation-executor (Phase 3)
- test-specialist (Phase 4)
- debug-analyst (Phase 5, conditional)
- doc-writer (Phase 6, conditional)

**Output**:
- Research reports (specs/reports/)
- Implementation plan (specs/plans/)
- Code changes (Phase 3)
- Test results (Phase 4)
- Debug reports (Phase 5, if needed)
- Implementation summary (specs/summaries/)

**Performance**:
- File size: 2,500-3,000 lines (vs 5,438 for /orchestrate)
- Context usage: <30% throughout workflow
- Time savings: 40-60% (wave-based execution)

**See**: [coordinate.md](../../commands/coordinate.md)

---

### /debug
**Purpose**: Investigate issues and create diagnostic reports without code changes

**Usage**: `/debug <issue-description> [report-path1] [report-path2] ...`

**Type**: support

**Arguments**:
- `issue-description`: Description of the issue to investigate
- `report-paths` (optional): Research reports for context

**Agents Used**: debug-specialist

**Output**: Diagnostic report in `debug/{topic}/NNN_description.md`

**See**: [debug.md](../../commands/debug.md)

---

### /document
**Purpose**: Update documentation based on recent code changes

**Usage**: `/document [change-description] [scope]`

**Type**: support

**Arguments**:
- `change-description` (optional): What changed
- `scope` (optional): Specific files/directories to document

**Agents Used**: doc-writer

**Output**: Updated README files and documentation

**See**: [document.md](../../commands/document.md)

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

### /implement
**Purpose**: Execute implementation plans with automated testing and commits

**Usage**: `/implement [plan-file] [starting-phase]`

**Type**: primary

**Arguments**:
- `plan-file` (optional): Path to plan (auto-resumes latest if omitted)
- `starting-phase` (optional): Phase number to start from

**Agents Used**: code-writer (per phase), test-specialist (testing), github-specialist (PR creation)

**Output**: Implemented code, git commits, implementation summary

**Dependent Commands**: list, revise, debug, document

**See**: [implement.md](../../commands/implement.md)

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

### /orchestrate
**Purpose**: Coordinate subagents through end-to-end development workflows

**Usage**: `/orchestrate <workflow-description> [--parallel] [--sequential] [--create-pr]`

**Type**: primary

**Arguments**:
- `workflow-description`: Feature or workflow to implement
- `--parallel`: Run independent phases in parallel
- `--sequential`: Force sequential execution
- `--create-pr`: Create GitHub PR on completion

**Agents Used**: All agents (research-specialist, plan-architect, code-writer, test-specialist, debug-specialist, doc-writer, github-specialist)

**Output**: Research reports, implementation plan, code changes, tests, documentation, optional PR

**See**: [orchestrate.md](../../commands/orchestrate.md)

---

### /plan
**Purpose**: Create detailed implementation plans following project standards

**Usage**: `/plan <feature-description> [report-path1] [report-path2] ...`

**Type**: primary

**Arguments**:
- `feature-description`: Feature to implement
- `report-paths` (optional): Research reports to incorporate

**Agents Used**: plan-architect

**Output**: Implementation plan file in `specs/plans/NNN_plan_name.md`

**Dependent Commands**: report, implement, revise

**See**: [plan.md](../../commands/plan.md)

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

**See**: [report.md](../../commands/report.md)

---

### /revise
**Purpose**: Revise existing plan or report with new requirements (content modification)

**Usage**:
- `/revise <revision-details> [context-path1] ...` (revision-first)
- `/revise <artifact-path> <revision-details> [context-path1] ...` (path-first)

**Type**: workflow

**Arguments**:
- `revision-details`: What to change
- `artifact-path`: Path to plan or report
- `context-paths` (optional): Additional context (reports, files)

**Agents Used**: None (direct modification) or plan-architect (complex changes)

**Output**: Updated plan or report with modifications

**See**: [revise.md](../../commands/revise.md)

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

**Agents Used**: test-specialist (test creation if needed)

**Output**: Test results and analysis

**See**: [test.md](../../commands/test.md)

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

**See**: [update.md](../../commands/update.md), [Command Selection Guide](../guides/command-development-guide.md)

---

## Commands by Type

### Primary Commands
Core development workflow drivers:
- **/implement** - Execute implementation plans with testing and commits
- **/orchestrate** - Coordinate multi-agent end-to-end workflows
- **/plan** - Create detailed implementation plans
- **/report** - Research topics and create reports
- **/test** - Run project-specific tests
- **/test-all** - Run complete test suite

### Support Commands
Specialized assistance commands:
- **/debug** - Investigate issues with diagnostic reports
- **/document** - Update documentation based on code changes
- **/plan-from-template** - Generate plans from templates
- **/plan-wizard** - Interactive plan creation wizard
- **/refactor** - Analyze code for refactoring opportunities

### Workflow Commands
Execution state and artifact management:
- **/collapse** - Merge expanded phases/stages back to parent
- **/expand** - Extract phases/stages to separate files
- **/revise** - Modify plan or report content
- **/update** - ⚠️ DEPRECATED (use /revise)

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
- **/orchestrate** (research phase)
- **/plan-wizard** (optional research phase)
- **/report**

### plan-architect
Structured implementation planning:
- **/orchestrate** (planning phase)
- **/plan**
- **/revise** (complex plan changes)

### code-writer
Feature implementation:
- **/orchestrate** (implementation phase)
- **/implement** (phase-by-phase)

### test-specialist
Test creation and execution:
- **/orchestrate** (testing phase)
- **/implement** (test execution)
- **/test** (test creation if needed)

### debug-specialist
Issue investigation:
- **/orchestrate** (debugging loop)
- **/debug**

### doc-writer
Documentation updates:
- **/orchestrate** (documentation phase)
- **/document**

### doc-converter
Document format conversion:
- **/convert-docs** (optional)

### github-specialist
GitHub operations:
- **/orchestrate** (PR creation)
- **/implement** (PR creation with --create-pr)

### code-analyzer
Code quality analysis:
- **/refactor**

---

## Related Documentation

- **[Creating Commands](../guides/command-development-guide.md)** - Comprehensive guide for developing commands
- **[Command Patterns](../guides/command-patterns.md)** - Reusable implementation patterns
- **[Agent Reference](agent-reference.md)** - Quick agent reference (Phase 4)
- **[Command Selection Guide](../guides/command-development-guide.md)** - Decision tree for choosing commands
- **[Commands README](../.claude/commands/README.md)** - Complete command documentation

---

**Notes**:
- Command count: 20 active commands + 1 deprecated
- All commands support CLAUDE.md standards discovery
- Commands can invoke specialized agents for complex tasks
- Progressive plan structure (L0/L1/L2) supported by plan-related commands
- Artifact organization: specs/ (gitignored), debug/ (tracked)
