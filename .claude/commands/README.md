# Commands Directory

Custom slash command definitions for Claude Code. Each command extends Claude's capabilities with specialized workflows for development, documentation, testing, and project management.

**Current Command Count**: 11 active commands

## Command Highlights

**/coordinate** (Production Orchestrator):
- State machine architecture with 48.9% code reduction vs legacy orchestrators
- Research phase creates persistent report files in `specs/reports/{topic}/`
- Debug loop creates persistent debug reports in `debug/{topic}/`
- Planning phase cross-references research reports automatically
- Documentation phase generates comprehensive workflow summaries
- Complete artifact traceability from research through implementation
- Wave-based parallel execution for 40-60% time savings

**Integration Benefits**:
- Agents create files directly (no inline summaries)
- Topic-based organization for better discoverability
- Clear separation: specs/ (gitignored) vs debug/ (tracked)
- Full end-to-end workflow automation with proper documentation
- Intelligent error recovery with persistent debugging artifacts

## Purpose

Commands provide structured, repeatable workflows for:

- **Implementation**: Systematic feature development with testing and commits (/build)
- **Planning**: Creating detailed implementation plans from requirements (/plan)
- **Research**: Investigating topics and generating comprehensive reports (/research)
- **Debugging**: Root cause analysis and bug fixing (/debug)
- **Revision**: Updating existing plans with new insights (/revise)
- **Orchestration**: Coordinating complex multi-agent workflows (/coordinate)
- **Configuration**: Project setup and CLAUDE.md optimization (/setup)

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

#### /build
**Purpose**: Build-from-plan workflow - Implementation, testing, debug, and documentation phases

**Usage**: `/build [plan-file] [starting-phase] [--dry-run]`

**Type**: primary

**Dependent Agents**: implementer-coordinator, debug-analyst

**Features**:
- Execute existing implementation plans
- Wave-based parallel phase execution
- Automatic test execution and debugging
- Git commits for completed phases

**Documentation**: [Build Command Guide](../docs/guides/build-command-guide.md)

---

#### /coordinate
**Purpose**: Coordinate multi-agent workflows with wave-based parallel implementation (state machine architecture)

**Usage**: `/coordinate <workflow-description>`

**Type**: primary

**Dependent Agents**: research-specialist, plan-architect, implementer-coordinator, debug-analyst

**Features**:
- State machine architecture with 48.9% code reduction
- Research phase creates persistent reports in `specs/reports/`
- Debug loop creates persistent debug reports
- Wave-based parallel execution for 40-60% time savings
- Complete artifact traceability

**Documentation**: [Coordinate Usage Guide](../docs/guides/coordinate-usage-guide.md)

---

#### /debug
**Purpose**: Debug-focused workflow - Root cause analysis and bug fixing

**Usage**: `/debug <issue-description> [--file <path>] [--complexity 1-4]`

**Type**: primary

**Dependent Agents**: research-specialist, plan-architect, debug-analyst

**Features**:
- Root cause analysis
- Debug strategy generation
- Issue investigation with research
- Fix implementation guidance

**Documentation**: [Debug Command Guide](../docs/guides/debug-command-guide.md)

---

#### /plan
**Purpose**: Research and create new implementation plan workflow

**Usage**: `/plan <feature-description> [--file <path>] [--complexity 1-4]`

**Type**: primary

**Dependent Agents**: research-specialist, research-sub-supervisor, plan-architect

**Features**:
- Research-driven planning
- Comprehensive research reports
- Implementation plan generation
- Complexity assessment

**Documentation**: [Plan Command Guide](../docs/guides/plan-command-guide.md)

---

#### /research
**Purpose**: Research-only workflow - Creates comprehensive research reports without planning or implementation

**Usage**: `/research <workflow-description> [--file <path>] [--complexity 1-4]`

**Type**: primary

**Dependent Agents**: research-specialist, research-sub-supervisor

**Features**:
- Deep topic investigation
- Research report generation
- No planning or implementation
- Topic-based organization

**Documentation**: [Research Command Guide](../docs/guides/research-command-guide.md)

---

#### /revise
**Purpose**: Research and revise existing implementation plan workflow

**Usage**: `/revise <revision-description-with-plan-path> [--complexity 1-4]`

**Type**: primary

**Dependent Agents**: research-specialist, research-sub-supervisor, plan-architect

**Features**:
- Research-driven plan revision
- Existing plan updates
- Backup of original plan
- Integration of new insights

**Documentation**: [Revise Command Guide](../docs/guides/revise-command-guide.md)

---

#### /setup
**Purpose**: Setup or improve CLAUDE.md with smart extraction, cleanup optimization, validation, standards analysis, report-driven updates, and automatic documentation enhancement

**Usage**: `/setup [project-directory] [--cleanup [--dry-run] [--threshold aggressive|balanced|conservative]] [--validate] [--analyze] [--apply-report <report-path>] [--enhance-with-docs]`

**Type**: primary

**Features**:
- CLAUDE.md generation and optimization
- Section extraction and cleanup
- Standards analysis
- Report-driven updates
- Documentation enhancement

**Documentation**: [Setup Command Guide](../docs/guides/setup-command-guide.md)

---

### Workflow Commands

#### /expand
**Purpose**: Expand phases/stages automatically or expand a specific phase/stage into detailed file

**Usage**: `/expand <path> [--auto-mode]` or `/expand [phase|stage] <path> <number> [--auto-mode]`

**Type**: workflow

**Features**:
- On-demand phase/stage extraction
- Auto-analysis mode for complexity detection
- Automatic directory creation
- Metadata tracking
- Level 0 to 1 or Level 1 to 2 transitions
- JSON output mode for agent coordination

---

#### /collapse
**Purpose**: Collapse expanded phases/stages automatically or collapse specific phase/stage back into parent

**Usage**: `/collapse <path>` or `/collapse [phase|stage] <path> <number>`

**Type**: workflow

**Features**:
- Content merging back to parent
- Auto-analysis mode for simplification
- Directory cleanup
- Metadata updates
- Level 1 to 0 or Level 2 to 1 transitions

---

### Utility Commands

#### /convert-docs
**Purpose**: Convert between Markdown, Word (DOCX), and PDF formats bidirectionally

**Usage**: `/convert-docs <input-directory> [output-directory] [--use-agent]`

**Type**: primary

**Dependent Agents**: doc-converter

**Features**:
- Bidirectional format conversion
- Script mode (fast) or agent mode (comprehensive)
- Markdown, DOCX, and PDF support
- Quality reporting with agent mode

---

#### /optimize-claude
**Purpose**: Analyze CLAUDE.md and .claude/docs/ structure to generate optimization plans

**Usage**: `/optimize-claude`

**Type**: utility

**Features**:
- Multi-stage agent workflow
- Parallel research and analysis
- Bloat prevention
- Quality improvement planning

---

## Common Flags

Several flags are shared across multiple commands. This section provides detailed documentation for these common flags.

### --file

**Supported by**: `/plan`, `/research`, `/debug`

Load the command description from a file instead of providing it inline. Useful for long prompts or pre-prepared requirements.

**Syntax**: `--file <path>`

**Behavior**:
- Relative paths are converted to absolute paths
- File content replaces the positional description argument
- Original file is archived to `{topic_path}/prompts/$(basename file)` for traceability
- Warning issued if file is empty

**Example**:
```bash
/plan --file /path/to/requirements.md
/debug --file /tmp/error-log.md
```

### --complexity

**Supported by**: `/plan`, `/research`, `/debug`, `/revise`

Set the research depth level for investigation phases.

**Syntax**: `--complexity 1-4`

**Levels**:
- **1**: Minimal research - Quick scan, basic context
- **2**: Standard research - Default for `/research`, `/debug`, `/revise`
- **3**: Comprehensive research - Default for `/plan`, thorough investigation
- **4**: Deep investigation - Exhaustive analysis, multiple research angles

**Default Values**:
| Command | Default |
|---------|---------|
| `/plan` | 3 |
| `/research` | 2 |
| `/debug` | 2 |
| `/revise` | 2 |

**Example**:
```bash
/plan "Add authentication" --complexity 4
/research "API design patterns" --complexity 1
```

### --dry-run

**Supported by**: `/build`, `/setup --cleanup`

Preview mode that shows what would be done without making actual changes.

**Syntax**: `--dry-run`

**Behavior**:
- `/build --dry-run`: Shows phases and tasks that would execute
- `/setup --cleanup --dry-run`: Shows sections that would be extracted/removed

**Example**:
```bash
/build specs/plans/007_feature.md --dry-run
/setup --cleanup --dry-run
```

### --auto-mode

**Supported by**: `/expand`

Enable non-interactive JSON output mode for agent coordination and automation.

**Syntax**: `--auto-mode`

**Behavior**:
- Outputs structured JSON instead of interactive prompts
- Used by implementation-executor agents for automated plan expansion
- Returns expansion results in machine-parseable format

**Example**:
```bash
/expand specs/plans/025_feature.md --auto-mode
```

### --threshold

**Supported by**: `/setup --cleanup`

Set the aggressiveness level for CLAUDE.md cleanup operations.

**Syntax**: `--threshold aggressive|balanced|conservative`

**Levels**:
- **aggressive**: Extract more sections to external files
- **balanced**: Standard extraction thresholds
- **conservative**: Minimal extraction, keep more inline

**Example**:
```bash
/setup --cleanup --threshold aggressive
/setup --cleanup --threshold conservative --dry-run
```

### Mode Detection Keywords

**Applicable to**: `/convert-docs`

Certain keywords in the command description trigger agent mode automatically:
- "detailed logging"
- "quality reporting"
- "verify tools"
- "orchestrated workflow"

**Example**:
```bash
# These trigger agent mode automatically
/convert-docs ./docs ./output with detailed logging
/convert-docs ./files with quality reporting
```

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
- `/build`, `/coordinate`, `/plan`, `/research`, `/debug`, `/revise`, `/setup`, `/convert-docs`

### Workflow Commands
Commands for managing plan structure and state:
- `/expand`, `/collapse`

### Utility Commands
Analysis and optimization commands:
- `/optimize-claude`

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
- Use `/expand phase <plan> <phase-num>` to extract
- Example: `specs/plans/015_dashboard/`
  - `015_dashboard.md` (main plan with summaries)
  - `phase_2_components.md` (expanded phase)

**Level 2: Stage Expansion** (Created on-demand)
- Phase directories with stage subdirectories
- Created when phases have complex multi-stage workflows
- Use `/expand stage <phase> <stage-num>` to extract
- Example: `specs/plans/020_refactor/`
  - `020_refactor.md` (main plan)
  - `phase_1_analysis/`
    - `phase_1_overview.md`
    - `stage_1_codebase_scan.md`

### Progressive Command Behavior

All plan commands work with progressive structure levels:

- `/plan`: Creates Level 0 plan (single file), provides expansion hints if complex
- `/build`: Navigates structure level to find and execute phases
- `/revise`: Modifies plans with research integration
- `/expand phase`: Extracts phase to separate file (Level 0 to 1)
- `/expand stage`: Extracts stage to separate file (Level 1 to 2)
- `/collapse phase`: Merges phase back into main plan (Level 1 to 0)
- `/collapse stage`: Merges stage back into phase (Level 2 to 1)

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
- Use `/expand phase` when a phase becomes too complex
- Use `/expand stage` when phases need multi-stage breakdown
- Use `/collapse phase` or `/collapse stage` to simplify structure

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
[Used by: /build, /plan]
## Code Standards
- Indentation
- Line length
- Naming conventions
- Error handling

[Used by: /build]
## Testing Protocols
- Test commands
- Test patterns
- Coverage requirements

[Used by: /plan]
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
Commands can log to `.claude/data/logs/`:
- `.claude/data/logs/hook-debug.log`: Hook execution trace
- `.claude/data/logs/tts.log`: TTS notification history
- `.claude/data/metrics/*.jsonl`: Command execution metrics

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

See [Neovim Code Standards](../../nvim/docs/CODE_STANDARDS.md) for complete standards.

## Neovim Integration

Commands in this directory are integrated with the Neovim artifact picker for visual browsing and quick access.

### Accessing Commands via Picker

- **Keybinding**: `<leader>ac` in normal mode
- **Command**: `:ClaudeCommands`
- **Category**: [Commands] section in picker

### Picker Features for Commands

**Visual Display**:
- Commands organized hierarchically (primary → dependents)
- Local commands marked with `*` prefix
- Dependent commands nested under their parents
- Agent cross-references shown in preview

**Quick Actions**:
- `<CR>` - Insert command into Claude Code terminal
- `<C-l>` - Load command locally (with dependencies)
- `<C-g>` - Update from global version
- `<C-s>` - Save local command to global
- `<C-e>` - Edit command file in buffer
- `<C-u>`/`<C-d>` - Scroll preview up/down

**Example Workflow**:
```vim
" Open picker
:ClaudeCommands

" Navigate to /build command
" Press Return to insert "/build" in Claude Code
" Or press <C-e> to edit build.md file
```

### Command File Structure

Commands appear in the picker based on their metadata:

```yaml
---
command-type: primary         # Appears at root level
dependent-commands: report    # Shows 'report' nested below
description: Brief description shown in picker
---
```

**Primary commands** (e.g., `/build`, `/coordinate`) appear at the root level with their dependent commands nested below. **Dependent commands** can appear under multiple parents if referenced by multiple primary commands.

### Documentation

- [Neovim Claude Integration](../../nvim/lua/neotex/plugins/ai/claude/README.md) - Integration overview
- [Commands Picker](../../nvim/lua/neotex/plugins/ai/claude/commands/README.md) - Picker documentation
- [Picker Implementation](../../nvim/lua/neotex/plugins/ai/claude/commands/picker.lua) - Source code

## Navigation

### Command Definitions
- [build.md](build.md) - Build from plan execution
- [collapse.md](collapse.md) - Phase/stage collapse (Level 1 to 0, Level 2 to 1)
- [convert-docs.md](convert-docs.md) - Document format conversion
- [coordinate.md](coordinate.md) - Multi-agent workflow coordination (production orchestrator)
- [debug.md](debug.md) - Debug-focused workflow with root cause analysis
- [expand.md](expand.md) - Phase/stage expansion (Level 0 to 1, Level 1 to 2)
- [optimize-claude.md](optimize-claude.md) - CLAUDE.md optimization analysis
- [plan.md](plan.md) - Research and create implementation plans
- [research.md](research.md) - Research-only workflow for reports
- [revise.md](revise.md) - Research and revise existing plans
- [setup.md](setup.md) - CLAUDE.md setup and optimization

### Related
- [Parent Directory](../README.md)
- [Agents](../agents/README.md) - Agents used by commands
- [Specs](../specs/README.md) - Command outputs
- [Documentation](../docs/README.md) - Guides and references

## Examples

### Running Implementation
```bash
# Research and create plan
/plan "Add dark mode toggle to settings"

# Build from plan (single file)
/build specs/plans/007_dark_mode_implementation.md

# Expand complex phase during implementation
/expand phase specs/plans/007_dark_mode.md 2

# Build Level 1 plan (with expanded phase)
/build specs/plans/007_dark_mode/

# Auto-resume latest incomplete plan
/build
```

### Research Workflows
```bash
# Research the topic and create plan
/plan "TTS engine comparison for Linux"

# Research only (no plan)
/research "Authentication best practices"

# Debug workflow for issues
/debug "Login tests failing with timeout error"
```

### Progressive Plan Management
```bash
# Expand phase as complexity grows
/expand phase specs/plans/007_dark_mode.md 2

# Auto-expand all complex phases
/expand specs/plans/015_dashboard/

# Revise plan with research
/revise "Add Phase 9: Performance testing to specs/plans/015_dashboard/"

# Collapse phase to simplify
/collapse phase specs/plans/015_dashboard/ 5

# Auto-collapse simple phases
/collapse specs/plans/020_refactor/
```

### Full Workflow with Coordinate
```bash
# Complete workflow: research, plan, build, test
/coordinate "Implement user authentication with JWT tokens"

# Document conversion
/convert-docs ./docs ./output

# Setup project standards
/setup --analyze
```

### Using Flags
```bash
# Load description from file with high complexity
/plan --file /path/to/requirements.md --complexity 4

# Debug with external issue description
/debug --file /tmp/error-log.md --complexity 3

# Quick research with minimal depth
/research "API design patterns" --complexity 1

# Revise plan with comprehensive research
/revise "Add caching layer to specs/plans/015_api.md" --complexity 4

# Setup with aggressive cleanup preview
/setup --cleanup --threshold aggressive --dry-run

# Expand with JSON output for automation
/expand specs/plans/025_feature.md --auto-mode

# Preview build execution
/build specs/plans/007_feature.md --dry-run

# Agent mode document conversion
/convert-docs ./docs ./output --use-agent
```
