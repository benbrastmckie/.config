# Commands Directory

Custom slash command definitions for Claude Code. Each command extends Claude's capabilities with specialized workflows for development, documentation, testing, and project management.

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

**Dependencies**: list-plans, update-plan, list-summaries, revise, debug, document

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

### Workflow Commands

#### /resume-implement
**Purpose**: Resume implementation from incomplete plan or specific phase

**Usage**: `/resume-implement [plan-file] [phase-number]`

**Features**:
- Auto-detect incomplete plans
- Phase resumption
- State recovery
- Context restoration

---

#### /revise
**Purpose**: Revise existing implementation plan with new requirements

**Usage**: `/revise <revision-details> [report-path1] [report-path2] ...`

**Features**:
- Plan modification
- Research integration
- Phase adjustment
- No implementation (planning only)

---

#### /update-plan
**Purpose**: Update existing implementation plan

**Usage**: `/update-plan <plan-path> [reason-for-update]`

**Features**:
- Plan modification
- Phase updates
- Requirement changes
- Version control

---

#### /update-report
**Purpose**: Update existing research report with new findings

**Usage**: `/update-report <report-path> [specific-sections]`

**Features**:
- Section updates
- New information integration
- Consistency maintenance
- Version tracking

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
- Plan discovery
- Status indication
- Search filtering
- Recent first ordering

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
- `/resume-implement`, `/revise`, `/update-plan`, `/update-report`

### Utility Commands
Management and maintenance commands:
- `/cleanup`, `/list-*`, `/setup`, `/validate-setup`

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
- [orchestrate.md](orchestrate.md) - Multi-agent coordination
- [plan.md](plan.md) - Implementation planning
- [plan-wizard.md](plan-wizard.md) - Interactive plan creation
- [refactor.md](refactor.md) - Code analysis
- [report.md](report.md) - Research reports
- [resume-implement.md](resume-implement.md) - Resume implementation
- [revise.md](revise.md) - Plan revision
- [setup.md](setup.md) - CLAUDE.md setup
- [test.md](test.md) - Test execution
- [test-all.md](test-all.md) - Full test suite
- [update-plan.md](update-plan.md) - Plan updates
- [update-report.md](update-report.md) - Report updates
- [validate-setup.md](validate-setup.md) - Setup validation

### Related
- [← Parent Directory](../README.md)
- [agents/](../agents/README.md) - Agents used by commands
- [specs/](../specs/README.md) - Command outputs
- [docs/command-standards-flow.md](../docs/command-standards-flow.md) - Standards integration

## Examples

### Running Implementation
```bash
# Create plan first
/plan "Add dark mode toggle to settings"

# Implement the plan
/implement specs/plans/007_dark_mode_implementation.md

# Or just auto-resume latest incomplete plan
/implement
```

### Research and Plan
```bash
# Research the topic
/report "TTS engine comparison for Linux"

# Create plan using research
/plan "Integrate TTS notifications" specs/reports/020_tts_engines.md
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
