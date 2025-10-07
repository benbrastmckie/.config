# Commands Directory

Custom slash command definitions for Claude Code. Each command extends Claude's capabilities with specialized workflows for development, documentation, testing, and project management.

**Current Command Count**: 26 commands (reduced from 29 through consolidation)

## Recent Changes

### Command Consolidation (2025-10-06)
Consolidated redundant commands for a cleaner interface:
- `/cleanup` → **Removed** (use `/setup --cleanup` instead)
- `/validate-setup` → **Removed** (use `/setup --validate` instead)
- `/analyze-agents` + `/analyze-patterns` → **Removed** (use `/analyze [type]` instead)

**Migration**: See `.claude/docs/MIGRATION_GUIDE.md` for command replacements

### Shared Utilities Integration (2025-10-06)
Commands now reference shared utility libraries in `.claude/lib/`:
- `checkpoint-utils.sh` - Workflow state persistence
- `complexity-utils.sh` - Phase complexity analysis
- `artifact-utils.sh` - Artifact tracking and registry
- `error-utils.sh` - Error classification and recovery
- `adaptive-planning-logger.sh` - Adaptive planning logging

## Purpose

Commands provide structured, repeatable workflows for:

- **Implementation**: Systematic feature development with testing and commits
- **Planning**: Creating detailed implementation plans from requirements
- **Research**: Investigating topics and generating comprehensive reports
- **Testing**: Running tests and analyzing results
- **Documentation**: Updating documentation based on code changes
- **Refactoring**: Analyzing and improving code quality
- **Orchestration**: Coordinating complex multi-agent workflows

## Command Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ User Input: /command [args]                                │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ Command Definition (.claude/commands/command.md)            │
├─────────────────────────────────────────────────────────────┤
│ • Metadata: tools, arguments, dependencies                  │
│ • Instructions: workflow steps and logic                    │
│ • Standards discovery: CLAUDE.md integration                │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ Execution                                                   │
├─────────────────────────────────────────────────────────────┤
│ • Read relevant files                                       │
│ • Apply project standards                                   │
│ • Invoke agents if needed                                   │
│ • Execute workflow steps                                    │
│ • Report results                                            │
└─────────────────────────────────────────────────────────────┘
```

## Available Commands

### Primary Commands

#### /implement
**Purpose**: Execute implementation plans with automated testing and commits

**Usage**: `/implement [plan-file] [starting-phase]`

**Features**:
- Auto-resume from incomplete plans
- Phase-by-phase execution
- Automated testing after each phase
- Git commits with descriptive messages
- Standards discovery and application

**Dependencies**: list, update, revise, debug, document

---

#### /plan
**Purpose**: Create detailed implementation plans following project standards

**Usage**: `/plan <feature description> [report-path1] [report-path2] ...`

**Features**:
- Research report integration
- Phase breakdown
- Success criteria definition
- Risk assessment
- Standards compliance

**Output**: `specs/plans/NNN_plan_name.md`

---

#### /plan-wizard
**Purpose**: Interactive wizard for guided plan creation with research integration

**Usage**: `/plan-wizard`

**Features**:
- Step-by-step interactive prompts
- Component and scope analysis
- Automatic research topic identification
- Complexity assessment
- Optional research execution
- Integration with /plan command

**Output**: `specs/plans/NNN_plan_name.md`

---

#### /report
**Purpose**: Research topics and create comprehensive reports

**Usage**: `/report <topic or question>`

**Features**:
- Web research integration
- Technology investigation
- Best practices analysis
- Structured markdown output

**Output**: `specs/reports/NNN_report_name.md`

---

#### /test
**Purpose**: Run project-specific tests based on CLAUDE.md protocols

**Usage**: `/test <feature/module/file> [test-type]`

**Features**:
- CLAUDE.md test command discovery
- Language-specific test patterns
- Result analysis
- Failure diagnosis

---

#### /test-all
**Purpose**: Run complete test suite for the project

**Usage**: `/test-all [coverage]`

**Features**:
- Full project testing
- Coverage reporting
- Performance analysis
- Standards compliance

---

#### /orchestrate
**Purpose**: Coordinate subagents through end-to-end development workflows

**Usage**: `/orchestrate <workflow-description> [--parallel] [--sequential]`

**Features**:
- Multi-agent coordination
- Parallel or sequential execution
- Progress tracking
- Error handling and recovery

---

### Support Commands

#### /debug
**Purpose**: Investigate issues and create diagnostic reports without code changes

**Usage**: `/debug <issue-description> [report-path1] [report-path2] ...`

**Features**:
- Read-only investigation
- Diagnostic report generation
- Root cause analysis
- Research report integration

---

#### /document
**Purpose**: Update documentation based on recent code changes

**Usage**: `/document [change-description] [scope]`

**Features**:
- Automatic change detection
- README updates
- API documentation
- Navigation link maintenance

---

#### /refactor
**Purpose**: Analyze code for refactoring opportunities

**Usage**: `/refactor [file/directory/module] [specific-concerns]`

**Features**:
- Code quality analysis
- Standards compliance checking
- Refactoring recommendations
- Detailed report generation

---

#### /plan-from-template
**Purpose**: Generate implementation plans from reusable templates

**Usage**: `/plan-from-template <template-name>`

**Features**:
- Variable substitution ({{variable}})
- Pre-built templates (CRUD, API, refactoring)
- Custom template support
- 60-80% faster plan creation

**Templates**:
- crud-feature: CRUD operations for entities
- api-endpoint: REST API implementation
- refactoring: Structured code refactoring

**Output**: `specs/plans/NNN_plan_name.md`

---

#### /analyze-patterns
**Purpose**: Analyze learning data for workflow insights and optimization opportunities

**Usage**: `/analyze-patterns [search-pattern]`

**Features**:
- Success rate analysis by workflow type
- Common research topics identification
- Implementation time statistics
- Failure pattern detection
- Optimization recommendations
- Visual charts and reports

**Output**: Console analysis + `specs/reports/NNN_pattern_analysis.md`

---

### Workflow Commands


#### /revise
**Purpose**: Revise existing implementation plan with new requirements

**Usage**: `/revise <revision-details> [report-path1] [report-path2] ...`

**Features**:
- Progressive structure-aware plan modification
- Revision scope analysis (high-level vs phase-specific)
- Research integration
- Phase adjustment
- No implementation (planning only)

---

#### /expand-phase
**Purpose**: Extract phase to separate file (Level 0 → 1 transition)

**Usage**: `/expand-phase <plan-path> <phase-num>`

**Features**:
- On-demand phase extraction
- Automatic directory creation
- Metadata tracking

#### /collapse-phase
**Purpose**: Merge phase file back into main plan (Level 1 → 0 transition)

**Usage**: `/collapse-phase <plan-path> <phase-num>`

**Features**:
- Content merging
- Directory cleanup
- Metadata updates

---

#### /update
**Purpose**: Update plan or report with new information

**Usage**:
- `/update plan <plan-path> [reason-for-update]`
- `/update report <report-path> [specific-sections]`

**Features**:
- **Plans**: Progressive structure-aware modification, phase updates, works with all levels (L0/L1/L2)
- **Reports**: Section updates, new information integration, version tracking
- Unified interface for both artifact types
- Cross-reference integrity maintenance

---

### Utility Commands

#### /analyze-agents
**Purpose**: Analyze agent performance metrics and generate insights report

**Usage**: `/analyze-agents`

**Features**:
- Agent performance rankings
- Efficiency scoring
- Success rate analysis
- Actionable recommendations

---

#### /cleanup
**Purpose**: Optimize CLAUDE.md by extracting sections to auxiliary files

**Usage**: `/cleanup [project-directory]`

**Features**:
- Section extraction
- File organization
- Link maintenance
- Standards compliance

**Note**: Integrated into `/setup --cleanup`

---

#### /list-plans
**Purpose**: List all implementation plans in the codebase

**Usage**: `/list-plans [search-pattern]`

**Features**:
- Plan discovery (all levels)
- Level indicators: [L0], [L1], [L2]
- Expansion status indication
- Phase count and completion
- Search filtering
- Recent first ordering
- Complexity statistics by level

---

#### /list-reports
**Purpose**: List all research reports in the codebase

**Usage**: `/list-reports [search-pattern]`

**Features**:
- Report discovery
- Topic display
- Search filtering
- Chronological ordering

---

#### /list-summaries
**Purpose**: List implementation summaries showing plans executed and reports used

**Usage**: `/list-summaries [search-pattern]`

**Features**:
- Summary discovery
- Plan linkage
- Report references
- Execution history

---

#### /setup
**Purpose**: Setup or improve CLAUDE.md with smart extraction and optimization

**Usage**: `/setup [project-directory] [--cleanup [--dry-run]] [--analyze] [--apply-report <report-path>]`

**Features**:
- CLAUDE.md generation
- Section optimization
- Standards analysis
- Report-driven updates

---

#### /validate-setup
**Purpose**: Validate CLAUDE.md setup and check linked standards files

**Usage**: `/validate-setup [project-directory]`

**Features**:
- CLAUDE.md validation
- Link verification
- Standards checking
- Error reporting

---

## Command Definition Format

Each command is defined in a markdown file with frontmatter metadata:

```markdown
---
allowed-tools: Read, Edit, Write, Bash, Grep, Glob, TodoWrite
argument-hint: [arg1] [arg2]
description: Brief command description
command-type: primary
dependent-commands: cmd1, cmd2, cmd3
---

# Command Name

Detailed description and instructions.

## Usage
/command <required-arg> [optional-arg]

## Standards Discovery and Application
How the command discovers and applies CLAUDE.md standards

## Workflow
Step-by-step execution process

## Output
What the command produces
```

### Metadata Fields

- **allowed-tools**: Tools the command can use
- **argument-hint**: Argument format for help text
- **description**: One-line summary
- **command-type**: `primary`, `support`, `workflow`, or `utility`
- **dependent-commands**: Related commands

## Command Types

### Primary Commands
Main workflow drivers that users invoke frequently:
- `/implement`, `/plan`, `/report`, `/test`, `/orchestrate`

### Support Commands
Helper commands for specific tasks:
- `/debug`, `/document`, `/refactor`

### Workflow Commands
Commands for managing execution state:
- `/revise`, `/update`

### Utility Commands
Management and maintenance commands:
- `/cleanup`, `/list-*`, `/setup`, `/validate-setup`

## Adaptive Plan Structures

Commands support progressive plan organization that grows based on actual complexity:

### Progressive Structure Levels

**Level 0: Single File** (All plans start here)
- Single `.md` file with all content
- All features start here, regardless of anticipated complexity
- Example: `specs/plans/001_button_fix.md`

**Level 1: Phase Expansion** (Created on-demand)
- Directory with some phases in separate files
- Created when phases prove too complex during implementation
- Use `/expand-phase <plan> <phase-num>` to extract
- Example: `specs/plans/015_dashboard/`
  - `015_dashboard.md` (main plan with summaries)
  - `phase_2_components.md` (expanded phase)

**Level 2: Stage Expansion** (Created on-demand)
- Phase directories with stage subdirectories
- Created when phases have complex multi-stage workflows
- Use `/expand-stage <phase> <stage-num>` to extract
- Example: `specs/plans/020_refactor/`
  - `020_refactor.md` (main plan)
  - `phase_1_analysis/`
    - `phase_1_overview.md`
    - `stage_1_codebase_scan.md`

### Progressive Command Behavior

All plan commands work with progressive structure levels:

- `/plan`: Creates Level 0 plan (single file), provides expansion hints if complex
- `/implement`: Navigates structure level to find and execute phases
- `/list plans`: Shows level indicators [L0], [L1], [L2]
- `/update plan`: Modifies correct files based on expansion status
- `/revise`: Analyzes revision scope to target appropriate file(s)
- `/expand-phase`: Extracts phase to separate file (Level 0 → 1)
- `/expand-stage`: Extracts stage to separate file (Level 1 → 2)
- `/collapse-phase`: Merges phase back into main plan (Level 1 → 0)
- `/collapse-stage`: Merges stage back into phase (Level 2 → 1)

### Parsing Utility

Advanced users can use the progressive parsing utility directly:

```bash
# Detect plan structure level
.claude/lib/parse-adaptive-plan.sh detect_structure_level <plan-path>

# Check if plan is expanded
.claude/lib/parse-adaptive-plan.sh is_plan_expanded <plan-path>

# Check if specific phase is expanded
.claude/lib/parse-adaptive-plan.sh is_phase_expanded <plan-path> <phase-num>

# List expanded phases
.claude/lib/parse-adaptive-plan.sh list_expanded_phases <plan-path>

# List expanded stages for a phase
.claude/lib/parse-adaptive-plan.sh list_expanded_stages <plan-path> <phase-num>

# Get plan status
.claude/lib/parse-adaptive-plan.sh get_status <plan-path>
```

### Progressive Expansion

Plans grow organically during implementation:
- All plans start as Level 0 (single file)
- Use `/expand-phase` when a phase becomes too complex
- Use `/expand-stage` when phases need multi-stage breakdown
- Use `/collapse-phase` or `/collapse-stage` to simplify structure

# Estimate metrics from description
.claude/lib/analyze-plan-requirements.sh "<feature description>"
```

## Standards Discovery

Commands discover project standards through CLAUDE.md:

### Discovery Process
1. **Locate CLAUDE.md**: Search upward from working directory
2. **Parse Sections**: Extract relevant sections (Code Standards, Testing Protocols, etc.)
3. **Check Subdirectories**: Look for directory-specific CLAUDE.md files
4. **Merge Standards**: Subdirectory standards extend/override parent standards
5. **Apply Fallbacks**: Use language-specific defaults if standards missing

### Standards Sections Used

```markdown
[Used by: /implement, /refactor, /plan]
## Code Standards
- Indentation
- Line length
- Naming conventions
- Error handling

[Used by: /test, /test-all, /implement]
## Testing Protocols
- Test commands
- Test patterns
- Coverage requirements

[Used by: /document, /plan]
## Documentation Policy
- README requirements
- Documentation format
```

## Creating Custom Commands

### Step 1: Define Purpose
Identify what workflow the command will automate.

### Step 2: Design Workflow
Break down the command into clear steps.

### Step 3: Choose Tools
Select minimal tools needed for the workflow.

### Step 4: Write Definition
Create command markdown file with metadata and instructions.

```bash
# Create new command
nvim .claude/commands/your-command.md
```

### Step 5: Add Metadata
Include allowed tools, arguments, and dependencies.

### Step 6: Document Standards
Explain how the command discovers and applies CLAUDE.md standards.

### Step 7: Test
Run the command: `/your-command [args]`

## Command Integration

### With Agents
Commands can invoke agents for specialized tasks:

```markdown
I'll invoke the code-writer agent to implement this feature.
[Agent invocation with context]
```

### With Hooks
Commands trigger hooks on completion:
- `Stop`: Metrics collection, TTS notification
- Custom hooks for command-specific actions

### With Logging
Commands can log to `.claude/logs/`:
- `.claude/logs/hook-debug.log`: Hook execution trace
- `.claude/logs/tts.log`: TTS notification history
- `.claude/metrics/*.jsonl`: Command execution metrics

## Best Practices

### Command Design
- **Single purpose**: Each command does one thing well
- **Clear arguments**: Intuitive argument structure
- **Standards aware**: Always discover and apply CLAUDE.md standards
- **Error handling**: Graceful failure with helpful messages

### Workflow Steps
- **Incremental**: Break into small, testable steps
- **Validated**: Verify each step before proceeding
- **Reversible**: Allow undo where possible
- **Documented**: Track what was done for summaries

### Output
- **Structured**: Use consistent formats (JSONL, markdown)
- **Traceable**: Include timestamps and context
- **Comprehensive**: Provide complete information
- **Actionable**: Include next steps or recommendations

## Documentation Standards

All commands follow documentation standards:

- **NO emojis** in file content
- **Unicode box-drawing** for diagrams
- **Clear examples** with syntax highlighting
- **Complete workflows** from start to finish
- **CommonMark** specification

See [/home/benjamin/.config/nvim/docs/GUIDELINES.md](../../nvim/docs/GUIDELINES.md) for complete standards.

## Navigation

### Command Definitions
- [analyze-agents.md](analyze-agents.md) - Agent performance analysis
- [cleanup.md](cleanup.md) - CLAUDE.md optimization
- [debug.md](debug.md) - Issue investigation
- [document.md](document.md) - Documentation updates
- [implement.md](implement.md) - Plan execution
- [list-plans.md](list-plans.md) - Plan listing
- [list-reports.md](list-reports.md) - Report listing
- [list-summaries.md](list-summaries.md) - Summary listing
- [expand-phase.md](expand-phase.md) - Phase expansion (L0→L1)
- [expand-stage.md](expand-stage.md) - Stage expansion (L1→L2)
- [collapse-phase.md](collapse-phase.md) - Phase collapse (L1→L0)
- [collapse-stage.md](collapse-stage.md) - Stage collapse (L2→L1)
- [orchestrate.md](orchestrate.md) - Multi-agent coordination
- [plan.md](plan.md) - Implementation planning
- [plan-wizard.md](plan-wizard.md) - Interactive plan creation
- [refactor.md](refactor.md) - Code analysis
- [report.md](report.md) - Research reports
- [revise.md](revise.md) - Plan revision
- [setup.md](setup.md) - CLAUDE.md setup
- [test.md](test.md) - Test execution
- [test-all.md](test-all.md) - Full test suite
- [update.md](update.md) - Plan and report updates
- [validate-setup.md](validate-setup.md) - Setup validation

### Related
- [← Parent Directory](../README.md)
- [agents/](../agents/README.md) - Agents used by commands
- [specs/](../specs/README.md) - Command outputs
- [docs/command-standards-flow.md](../docs/command-standards-flow.md) - Standards integration

## Examples

### Running Implementation
```bash
# Create plan (always starts as Level 0)
/plan "Add dark mode toggle to settings"

# Implement Level 0 plan (single file)
/implement specs/plans/007_dark_mode_implementation.md

# Expand complex phase during implementation
/expand-phase specs/plans/007_dark_mode.md 2

# Implement Level 1 plan (with expanded phase)
/implement specs/plans/007_dark_mode/

# Or just auto-resume latest incomplete plan
/implement
```

### Research and Plan
```bash
# Research the topic
/report "TTS engine comparison for Linux"

# Create plan using research (creates Level 0 plan)
/plan "Integrate TTS notifications" specs/reports/020_tts_engines.md
```

### Progressive Plan Management
```bash
# List all plans with level indicators
/list-plans
# Output: [L0] 007_dark_mode (3/3 phases)
#         [L1] 015_dashboard (5/8 phases, P:2,5)
#         [L2] 020_refactor (15/25 phases, P:3[S:1,2])

# Expand phase as complexity grows
/expand-phase specs/plans/007_dark_mode.md 2

# Update Level 1 plan (modifies appropriate files)
/update plan specs/plans/015_dashboard/ "Add Phase 9: Performance testing"

# Revise specific phase
/revise "Update Phase 3 complexity to High" specs/plans/015_dashboard/

# Collapse phase to simplify
/collapse-phase specs/plans/015_dashboard/ 5
```

### Testing Workflow
```bash
# Test specific feature
/test auth/login

# Run full suite
/test-all coverage

# Debug failures
/debug "Login tests failing with timeout error"
```
