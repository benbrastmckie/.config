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
- [/collapse](#collapse)
- [/convert-docs](#convert-docs)
- [/document](#document)
- [/errors](#errors)
- [/example-with-agent](#example-with-agent)
- [/expand](#expand)
- [/implement](#implement)
- [/lean-build](#lean-build)
- [/lean-implement](#lean-implement)
- [/lean-plan](#lean-plan)
- [/lean-update](#lean-update)
- [/list](#list)
- [/optimize-claude](#optimize-claude)
- [/create-plan](#create-plan)
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
- [/build](#build-archived)
- [/coordinate](#coordinate-archived)
- [/debug](#debug-archived)
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

### /build
**Status**: ARCHIVED - Use `/implement` + `/test` instead

**Purpose**: Build-from-plan workflow - Implementation, testing, debug, and documentation phases

**Migration**: This command has been archived. Use `/implement` for implementation phases and `/test` for test execution with debug loop.

**Reason for Removal**: The /build command combined too many responsibilities. Separating implementation (/implement) and testing (/test) provides clearer separation of concerns, more flexible execution, and better debugging isolation.

**Archive Location**: Removed in clean-break refactoring (git history: commit removing build.md)

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
**Status**: ARCHIVED - Use `/implement`, `/plan`, `/research`, `/debug`, or `/revise` instead

**Purpose**: Clean multi-agent workflow orchestration with wave-based parallel implementation

**Migration**: This command has been archived and its functionality split into dedicated commands:
- `/implement` - For implementation workflows
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
- `--command <cmd>` (optional): Filter by command name (e.g., `/implement`, `/plan`)
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
**Status**: ACTIVE

**Purpose**: Execute implementation phases from plans with wave-based parallel execution

**Usage**: `/implement [plan-file] [starting-phase] [--dry-run] [--max-iterations=N]`

**Type**: orchestrator

**Arguments**:
- `plan-file` (optional): Path to implementation plan (auto-detects if omitted)
- `starting-phase` (optional): Phase number to start from (default: 1)
- `--dry-run`: Preview execution without running
- `--max-iterations=N`: Maximum iteration count (default: 5)

**Agents Used**: implementer-coordinator

**Output**: Implementation summaries in topic summaries directory

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

**Automatically updates TODO.md**: No (manual plan tracking via /implement)

**See**: [optimize-claude.md](../../commands/optimize-claude.md)

---

### /create-plan
**Purpose**: Research and create new implementation plan workflow

**Usage**: `/create-plan <feature-description> [--file <path>] [--complexity 1-4]`

**Type**: orchestrator

**Arguments**:
- `feature-description` (required): Feature to research and plan
- `--file` (optional): Path to file containing long prompt (archived to specs/NNN_topic/prompts/)
- `--complexity` (optional): Research depth 1-4 (default: 3)

**Agents Used**: research-specialist, research-sub-supervisor, plan-architect

**Output**: Research reports + implementation plan

**Workflow**: `research → plan → complete`

**Automatically updates TODO.md**: Yes (after new plan creation)

**See**: [create-plan.md](../../commands/create-plan.md)

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
- `--command` (optional): Filter by command name (e.g., `/implement`, `/plan`)
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

### /lean-plan
**Purpose**: Create Lean-specific implementation plan for theorem proving projects with Mathlib research and proof strategies

**Usage**: `/lean-plan "<description>" [--file <path>] [--complexity 1-4] [--project <path>]`

**Type**: orchestrator (Lean specialization)

**Arguments**:
- `description` (required): Natural language formalization goal
- `--file` (optional): Path to file with detailed prompt (archived to specs/NNN_topic/prompts/)
- `--complexity` (optional): Research depth 1-4 (default: 3)
- `--project` (optional): Lean project path (auto-detect if omitted)

**Agents Used**: topic-naming-agent, lean-research-specialist, lean-plan-architect

**Output**: Research reports + Lean implementation plan with theorem specifications

**Workflow**: `research → plan → complete`

**Plan Features**:
- Theorem-level granularity (individual theorems as tasks)
- Mathlib theorem discovery and recommendations
- Proof strategy specifications (tactics, approaches)
- Dependency tracking for wave-based parallel proving
- **Lean File** metadata for Tier 1 discovery
- Goal specifications (Lean 4 type signatures)

**Integration**: Plans execute with `/lean-build` or `/lean-implement` command for automated proving

**See**: [lean-plan-command-guide.md](../../guides/commands/lean-plan-command-guide.md)

---

### /lean-update
**Purpose**: Update Lean project maintenance documentation by scanning for sorry placeholders and synchronizing six-document ecosystem

**Usage**: `/lean-update [--verify] [--with-build] [--dry-run]`

**Type**: maintenance (Lean specialization)

**Arguments**:
- `--verify` (optional): Check cross-reference integrity without modifications
- `--with-build` (optional): Include `lake build` and `lake test` verification
- `--dry-run` (optional): Preview changes without applying updates

**Agents Used**: lean-maintenance-analyzer

**Output**: Updated maintenance documents (TODO.md, SORRY_REGISTRY.md, IMPLEMENTATION_STATUS.md, KNOWN_LIMITATIONS.md, MAINTENANCE.md, CLAUDE.md)

**Modes**:
1. **Scan Mode** (default): Update all maintenance documents based on current project state
2. **Verify Mode** (`--verify`): Check cross-reference integrity without modifications
3. **Build Mode** (`--with-build`): Include build/test verification
4. **Dry-Run Mode** (`--dry-run`): Preview changes without applying

**Key Features**:
- Automated sorry placeholder detection via grep
- Module completion percentage calculation
- Cross-reference integrity validation
- Preservation of manually-curated sections (Backlog, Saved, Resolved Placeholders)
- Git snapshot before updates (recovery mechanism)
- Multi-file atomic updates

**Preservation Policy**:
- TODO.md: Preserves Backlog and Saved sections
- SORRY_REGISTRY.md: Preserves Resolved Placeholders section
- IMPLEMENTATION_STATUS.md: Preserves lines with `<!-- MANUAL -->` comment
- Other docs: Preserves sections marked with `<!-- CUSTOM -->` or `<!-- MANUAL -->`

**Examples**:
```bash
# Standard workflow: Update all maintenance docs
/lean-update

# Check cross-references without modifying files
/lean-update --verify

# Preview changes before applying
/lean-update --dry-run

# Full verification including build/test
/lean-update --with-build
```

**Recovery**:
```bash
# View changes since snapshot
git diff <snapshot-hash>

# Restore specific file
git restore --source=<snapshot-hash> -- Documentation/ProjectInfo/SORRY_REGISTRY.md
```

**See**: [lean-update.md](../../commands/lean-update.md), [Lean Update Command Guide](../../docs/guides/commands/lean-update-command-guide.md)

---

### /lean-build
**Purpose**: Build proofs for all sorry markers in Lean files using wave-based orchestration

**Usage**: `/lean-build [lean-file | plan-file] [--prove-all | --verify] [--max-attempts=N] [--max-iterations=N]`

**Type**: orchestrator (Lean specialization)

**Arguments**:
- `lean-file` (required): Path to .lean file or plan.md with lean_file metadata
- `--prove-all`: Attempt to prove all sorry markers (default)
- `--verify`: Verify existing proofs without modification
- `--max-attempts=N`: Max proof attempts per theorem (default: 3)
- `--max-iterations=N`: Max iteration loops (default: 5)

**Agents Used**: lean-coordinator, lean-implementer

**Output**: Proof summaries in topic summaries directory

**Workflow**: `setup → coordinate → prove → summarize`

**Features**:
- Wave-based parallel theorem proving
- MCP rate limit coordination (3 requests/30s)
- Mathlib theorem search integration
- Multi-file support for complex formalizations

**See**: [lean-build.md](../../commands/lean-build.md)

---

### /lean-implement
**Purpose**: Hybrid implementation command for mixed Lean/software plans with intelligent phase routing

**Usage**: `/lean-implement <plan-file> [starting-phase] [--mode=MODE] [--max-iterations=N]`

**Type**: orchestrator (hybrid Lean/software)

**Arguments**:
- `plan-file` (required): Path to implementation plan with mixed phases
- `starting-phase` (optional): Phase number to start from (default: 1)
- `--mode=MODE`: Execution mode - `auto`, `lean-only`, `software-only` (default: auto)
- `--max-iterations=N`: Max iteration loops (default: 5)
- `--dry-run`: Preview phase classification without executing

**Agents Used**: lean-coordinator (for Lean phases), implementer-coordinator (for software phases)

**Output**: Implementation and proof summaries in topic summaries directory

**Workflow**: `setup → classify → route → verify → summarize`

**Features**:
- 2-tier phase classification (metadata + keyword analysis)
- Intelligent routing to appropriate coordinator
- Mode filtering (lean-only, software-only, auto)
- Cross-coordinator iteration management
- Aggregated metrics from both coordinator types

**Phase Classification**:
- Tier 1: `lean_file:` metadata (strongest signal)
- Tier 2: Keywords (.lean, theorem, lemma) vs (.ts, .js, implement, create)
- Default: software (conservative approach)

**See**: [lean-implement-command-guide.md](../../guides/commands/lean-implement-command-guide.md)

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
- **/implement** - Execute implementation plans phase by phase
- **/debug** - Debug-focused workflow for root cause analysis
- **/create-plan** - Research and create implementation plans
- **/research** - Research-only workflow for reports
- **/revise** - Research and revise existing plans
- **/test** - Execute test suite with coverage loop

### Archived Commands
Legacy commands that have been superseded:
- **/build** - ARCHIVED (use /implement + /test)
- **/coordinate** - ARCHIVED (use /implement, /create-plan, /research, /debug, or /revise)
- **/debug** - ARCHIVED (use /debug)
- **/plan** - ARCHIVED (use /create-plan)
- **/research** - ARCHIVED (use /research or /create-plan)
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
- **/create-plan** (research phase)
- **/research** (research phase)
- **/plan-wizard** (optional research phase)
- **/report**

### plan-architect
Structured implementation planning:
- **/create-plan** (planning phase)
- **/revise** (complex plan changes)
- **/debug** (debug strategy planning)

### implementer-coordinator
Wave-based implementation execution:
- **/implement** (implementation phases)

### debug-analyst
Issue investigation:
- **/debug** (root cause analysis)
- **/test** (test failure debugging)

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
