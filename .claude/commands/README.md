# Commands Directory

Custom slash command definitions for Claude Code. Each command extends Claude's capabilities with specialized workflows for development, documentation, testing, and project management.

**Current Command Count**: 12 active commands

## Workflow

The core development workflow follows this sequence: **/research** -> **/plan** -> **/revise** -> **/build**

**/research** (Research-Only):
- Creates comprehensive research reports without planning or implementation
- Supports complexity levels 1-4 for varying investigation depth
- Topic-based organization in `specs/{NNN_topic}/reports/`

**/plan** (Research-Driven Planning):
- Executes research phase, then creates implementation plans
- Research reports persist in topic directories for cross-referencing
- Complexity-based depth adjustment (1-4, default 3)

**/revise** (Plan Revision):
- Updates existing plans with new research insights
- Creates backups before modification
- Integrates new research without losing existing progress

**/build** (Implementation Orchestrator):
- Executes plans with wave-based parallel phase execution
- Automatic test execution after each phase
- Git commits for completed phases
- Supports progressive plan structures (Level 0/1/2)

## Features

### Workflow Capabilities

- **Research**: Investigate topics and generate comprehensive reports (/research)
- **Planning**: Create detailed implementation plans from requirements (/plan)
- **Revision**: Update existing plans with new research insights (/revise)
- **Implementation**: Execute plans with testing and commits (/build)
- **Debugging**: Root cause analysis and bug fixing (/debug)

### Error Management Workflow

Commands and agents automatically log errors to a centralized queryable log. The error management workflow provides systematic error resolution:

**Error Lifecycle**:
```
┌─────────────────────────────────────────────────────────────────┐
│ ERROR PRODUCTION (Automatic)                                    │
├─────────────────────────────────────────────────────────────────┤
│ Commands/agents log errors via log_command_error()             │
│ Output: ~/.claude/data/errors.jsonl                            │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│ ERROR QUERYING (/errors)                                        │
├─────────────────────────────────────────────────────────────────┤
│ Filter and view logged errors by time, type, command           │
│ Output: Console display or summary report                      │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│ ERROR ANALYSIS (/repair)                                        │
├─────────────────────────────────────────────────────────────────┤
│ Group error patterns and create fix plan                       │
│ Output: Error analysis report + implementation plan            │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│ FIX IMPLEMENTATION (/build)                                     │
├─────────────────────────────────────────────────────────────────┤
│ Execute repair plan with tests and commits                     │
│ Output: Git commits for fixes                                  │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│ VERIFICATION (/errors)                                          │
├─────────────────────────────────────────────────────────────────┤
│ Confirm fixes resolved logged errors                           │
│ Output: Success confirmation                                   │
└─────────────────────────────────────────────────────────────────┘
```

**Usage Patterns**:

1. **Debugging Recent Failures**:
   ```bash
   /errors --since 1h --summary          # View recent error summary
   /repair --since 1h --complexity 2     # Analyze and create fix plan
   /build <repair-plan>                  # Implement fixes
   ```

2. **Systematic Error Cleanup**:
   ```bash
   /errors --type state_error --limit 20 # Identify error patterns
   /repair --type state_error            # Create comprehensive fix plan
   /build <repair-plan>                  # Execute repairs
   ```

3. **Targeted Command Analysis**:
   ```bash
   /errors --command /build --summary    # Analyze specific command errors
   /repair --command /build              # Create command-specific fix plan
   /build <repair-plan>                  # Implement improvements
   ```

**Key Commands**:
- **/errors**: Query error log with filters (time, type, command, severity)
- **/repair**: Analyze error patterns and generate fix plans
- **/build**: Execute repair plans with automatic testing

See [Errors Command Guide](../docs/guides/commands/errors-command-guide.md) and [Repair Command Guide](../docs/guides/commands/repair-command-guide.md) for complete workflow details.

### Technical Advantages

- **Agent-based execution**: Specialized agents for research, planning, implementation, and debugging
- **Skills integration**: Commands delegate to autonomous skills for focused capabilities
- **Topic organization**: All artifacts organized by `specs/{NNN_topic}/` structure
- **Artifact separation**: Gitignored specs vs tracked debug reports for clean commits
- **Full automation**: End-to-end workflow from research through implementation
- **Error recovery**: Intelligent debugging with persistent artifacts for analysis
- **Standards compliance**: Automatic discovery and application of CLAUDE.md standards

## Command Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ USER INPUT LAYER                                            │
├─────────────────────────────────────────────────────────────┤
│ /command <args> [--flags]                                   │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ COMMAND DEFINITION LAYER                                    │
├─────────────────────────────────────────────────────────────┤
│ File:        .claude/commands/command.md                    │
│ Frontmatter: allowed-tools, arguments, dependencies         │
│ Instructions: workflow steps, validation, error handling    │
│ Agent refs:  dependent-agents for specialized tasks         │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ LIBRARY LAYER                                               │
├─────────────────────────────────────────────────────────────┤
│ .claude/lib/                                                │
│ ├─ workflow-state-machine.sh (state orchestration)          │
│ ├─ state-persistence.sh (artifact tracking)                 │
│ ├─ error-handling.sh (recovery patterns)                    │
│ ├─ unified-location-detection.sh (path resolution)          │
│ └─ checkbox-utils.sh (progress tracking)                    │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ AGENT LAYER                                                 │
├─────────────────────────────────────────────────────────────┤
│ .claude/agents/                                             │
│ ├─ research-specialist (topic investigation)                │
│ ├─ plan-architect (plan generation)                         │
│ ├─ implementer-coordinator (wave-based execution)           │
│ └─ debug-analyst (root cause analysis)                      │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ OUTPUT LAYER                                                │
├─────────────────────────────────────────────────────────────┤
│ Artifacts: specs/{NNN_topic}/{reports,plans,summaries}/     │
│ State:     .claude/data/state/workflow_*.json               │
│ Logs:      .claude/data/logs/*.log                          │
└─────────────────────────────────────────────────────────────┘
```

## Skills Integration

Commands can delegate to skills for autonomous, model-invoked capabilities. Skills provide focused functionality that Claude automatically discovers and uses.

### Skills vs Commands vs Agents

| Aspect | Skills | Commands | Agents |
|--------|--------|----------|--------|
| Invocation | Autonomous (model-invoked) | Explicit (`/cmd`) | Task delegation |
| Scope | Single focused capability | Quick shortcuts | Complex orchestration |
| Discovery | Automatic | Manual | Manual |
| Context | Main conversation | Main conversation | Separate context |
| Composition | Auto-composition | Manual chaining | Coordinates skills |

### Command Delegation Pattern

Commands can delegate to skills when available, falling back to script mode when not:

```markdown
## STEP 0: Check Skill Availability

```bash
SKILL_AVAILABLE=false
if [ -d ".claude/skills/<skill-name>" ] && [ -f ".claude/skills/<skill-name>/SKILL.md" ]; then
  SKILL_AVAILABLE=true
  echo "Skill <skill-name> available"
fi
```

## STEP 3.5: Skill Delegation (after mode detection)

If $SKILL_AVAILABLE is true, delegate to skill via natural language:

"Use the <skill-name> skill to [perform task]"

Otherwise, fall back to script mode (STEP 4).
```

### Commands with Skills Integration

| Command | Integrated Skill | Delegation Mode |
|---------|------------------|-----------------|
| /convert-docs | document-converter | STEP 0/3.5 pattern |

### Benefits

- **Autonomous invocation**: Claude auto-invokes skills during workflows
- **Composition**: Skills compose automatically (e.g., research + document conversion)
- **Backward compatibility**: Commands fall back gracefully when skills unavailable
- **Token efficiency**: Progressive disclosure loads skill only when needed

### Documentation

- [Skills README](../skills/README.md) - Complete skills guide
- [Skills Authoring Standards](../docs/reference/standards/skills-authoring.md) - Standards compliance
- [Document Converter Skill Guide](../docs/guides/skills/document-converter-skill-guide.md) - Example integration

## Available Commands

### Primary Commands

#### /build
**Purpose**: Build-from-plan workflow - Implementation, testing, debug, and documentation phases

**Usage**: `/build [plan-file] [starting-phase] [--dry-run]`

**Type**: primary

**Example**:
```bash
/build specs/plans/007_dark_mode_implementation.md
```

**Dependencies**:
- **Agents**: implementer-coordinator, debug-analyst, spec-updater
- **Libraries**: workflow-state-machine.sh, state-persistence.sh, library-version-check.sh, error-handling.sh, checkpoint-utils.sh, checkbox-utils.sh

**Features**:
- Execute existing implementation plans
- Wave-based parallel phase execution
- Automatic test execution and debugging
- Git commits for completed phases

**Documentation**: [Build Command Guide](../docs/guides/commands/build-command-guide.md)

---

#### /debug
**Purpose**: Debug-focused workflow - Root cause analysis and bug fixing

**Usage**: `/debug <issue-description> [--file <path>] [--complexity 1-4]`

**Type**: primary

**Example**:
```bash
/debug "Login tests failing with timeout error"
```

**Dependencies**:
- **Agents**: research-specialist, plan-architect, debug-analyst, workflow-classifier
- **Libraries**: workflow-state-machine.sh, state-persistence.sh, library-version-check.sh, error-handling.sh, unified-location-detection.sh, workflow-initialization.sh

**Features**:
- Root cause analysis
- Debug strategy generation
- Issue investigation with research
- Fix implementation guidance

**Documentation**: [Debug Command Guide](../docs/guides/commands/debug-command-guide.md)

---

#### /plan
**Purpose**: Research and create new implementation plan workflow

**Usage**: `/plan <feature-description> [--file <path>] [--complexity 1-4]`

**Type**: primary

**Example**:
```bash
/plan "Add dark mode toggle to settings"
```

**Dependencies**:
- **Agents**: research-specialist, research-sub-supervisor, plan-architect
- **Libraries**: workflow-state-machine.sh, state-persistence.sh, library-version-check.sh, error-handling.sh, unified-location-detection.sh, workflow-initialization.sh

**Features**:
- Research-driven planning
- Comprehensive research reports
- Implementation plan generation
- Complexity assessment

**Documentation**: [Plan Command Guide](../docs/guides/commands/plan-command-guide.md)

---

#### /research
**Purpose**: Research-only workflow - Creates comprehensive research reports without planning or implementation

**Usage**: `/research <workflow-description> [--file <path>] [--complexity 1-4]`

**Type**: primary

**Example**:
```bash
/research "Authentication best practices"
```

**Dependencies**:
- **Agents**: research-specialist, research-sub-supervisor
- **Libraries**: workflow-state-machine.sh, state-persistence.sh, library-version-check.sh, error-handling.sh, unified-location-detection.sh, workflow-initialization.sh

**Features**:
- Deep topic investigation
- Research report generation
- No planning or implementation
- Topic-based organization

**Documentation**: [Research Command Guide](../docs/guides/commands/research-command-guide.md)

---

### Workflow Commands

#### /expand
**Purpose**: Expand phases/stages automatically or expand a specific phase/stage into detailed file

**Usage**: `/expand <path> [--auto-mode]` or `/expand [phase|stage] <path> <number> [--auto-mode]`

**Type**: workflow

**Example**:
```bash
/expand phase specs/plans/015_dashboard.md 2
```

**Dependencies**:
- **Agents**: complexity-estimator
- **Libraries**: plan-core-bundle.sh, auto-analysis-utils.sh, plan-core-bundle.sh

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

**Example**:
```bash
/collapse phase specs/plans/015_dashboard/ 5
```

**Dependencies**:
- **Agents**: complexity-estimator
- **Libraries**: plan-core-bundle.sh, auto-analysis-utils.sh

**Features**:
- Content merging back to parent
- Auto-analysis mode for simplification
- Directory cleanup
- Metadata updates
- Level 1 to 0 or Level 2 to 1 transitions

---

#### /revise
**Purpose**: Research and revise existing implementation plan workflow

**Usage**: `/revise <revision-description-with-plan-path> [--file <path>] [--complexity 1-4] [--dry-run]`

**Type**: workflow

**Example**:
```bash
/revise "Add Phase 9: Performance testing to specs/plans/015_api.md"
```

**Dependencies**:
- **Agents**: research-specialist, research-sub-supervisor, plan-architect
- **Libraries**: workflow-state-machine.sh, state-persistence.sh, library-version-check.sh, error-handling.sh

**Features**:
- Research-driven plan revision
- Existing plan updates
- Backup of original plan
- Integration of new insights

**Documentation**: [Revise Command Guide](../docs/guides/commands/revise-command-guide.md)

---

### Utility Commands

#### /errors
**Purpose**: Query and display error logs from commands and subagents with filtering and analysis capabilities

**Usage**: `/errors [--command CMD] [--since TIME] [--type TYPE] [--limit N] [--summary]`

**Type**: utility

**Example**:
```bash
/errors --command build --since "2 hours ago"
```

**Dependencies**:
- **Libraries**: error-handling.sh

**Features**:
- Centralized error log querying with rich context (timestamps, error types, workflow IDs, stack traces)
- Multiple filter options (command, time, type, workflow ID)
- Summary statistics and recent error views
- Automatic log rotation (10MB with 5 backups)
- Integrates with /repair for error analysis and fix planning

**Documentation**: [Errors Command Guide](../docs/guides/commands/errors-command-guide.md)

---

#### /repair
**Purpose**: Research error patterns and create implementation plan to fix them

**Usage**: `/repair [--since TIME] [--type TYPE] [--command CMD] [--severity LEVEL] [--complexity 1-4]`

**Type**: utility

**Example**:
```bash
/repair --since "1 week ago"
```

**Dependencies**:
- **Agents**: repair-analyst, plan-architect
- **Libraries**: workflow-state-machine.sh, state-persistence.sh

**Features**:
- Two-phase workflow: Error Analysis → Fix Planning (no implementation)
- Pattern-based error grouping and root cause analysis
- Integration with /errors command for log queries
- Complexity-aware analysis (default: 2 for error analysis)
- Generated plans executed via /build workflow
- Terminal state at plan creation (use /build to execute)

**Documentation**: [Repair Command Guide](../docs/guides/commands/repair-command-guide.md)

---

#### /setup
**Purpose**: Setup or improve CLAUDE.md with smart extraction, cleanup optimization, validation, standards analysis, report-driven updates, and automatic documentation enhancement

**Usage**: `/setup [project-directory] [--cleanup [--dry-run] [--threshold aggressive|balanced|conservative]] [--validate] [--analyze] [--apply-report <report-path>] [--enhance-with-docs]`

**Type**: utility

**Example**:
```bash
/setup --analyze
```

**Dependencies**:
- **Dependent Commands**: orchestrate (for enhance mode)
- **Libraries**: detect-testing.sh, generate-testing-protocols.sh, optimize-claude-md.sh

**Features**:
- CLAUDE.md generation and optimization
- Section extraction and cleanup
- Standards analysis
- Report-driven updates
- Documentation enhancement

**Documentation**: [Setup Command Guide](../docs/guides/commands/setup-command-guide.md)

---

#### /convert-docs
**Purpose**: Convert between Markdown, Word (DOCX), and PDF formats bidirectionally

**Usage**: `/convert-docs <input-directory> [output-directory] [--use-agent]`

**Type**: primary

**Example**:
```bash
/convert-docs ./docs ./output
```

**Dependencies**:
- **Agents**: doc-converter
- **Libraries**: convert-core.sh
- **External Tools**: MarkItDown, Pandoc, PyMuPDF4LLM

**Features**:
- Bidirectional format conversion
- Script mode (fast) or agent mode (comprehensive)
- Skill-based execution when document-converter skill available
- Markdown, DOCX, and PDF support
- Quality reporting with agent mode

**Documentation**: [Convert-Docs Command Guide](../docs/guides/commands/convert-docs-command-guide.md)

---

#### /optimize-claude
**Purpose**: Analyze CLAUDE.md and .claude/docs/ structure to generate optimization plans

**Usage**: `/optimize-claude`

**Type**: utility

**Dependencies**:
- **Agents**: claude-md-analyzer, docs-structure-analyzer, docs-bloat-analyzer, docs-accuracy-analyzer, cleanup-plan-architect
- **Libraries**: unified-location-detection.sh, optimize-claude-md.sh

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

## Adaptive Plan Structures

Commands support progressive plan organization that grows based on actual complexity discovered during implementation.

### Expansion Workflow

Plans grow organically as complexity emerges:

1. **All plans start as Level 0** (single file) - regardless of anticipated complexity
2. **Run `/expand phase <plan> <phase-num>`** when a phase becomes too complex during implementation
3. **Run `/expand stage <phase> <stage-num>`** when phases need multi-stage breakdown
4. **Use `/collapse`** commands to simplify structure when phases are reduced

**Example Workflow**:
```bash
# Start with Level 0 plan
/plan "Add dark mode toggle to settings"
# Creates: specs/plans/007_dark_mode.md

# Phase 2 proves complex during /build
/expand phase specs/plans/007_dark_mode.md 2
# Creates: specs/plans/007_dark_mode/phase_2_components.md

# Later simplify if needed
/collapse phase specs/plans/007_dark_mode/ 2
```

### Structure Levels

**Level 0: Single File**
- Format: `specs/plans/001_feature.md`
- All phases and tasks inline in one file
- All features start here

**Level 1: Phase Expansion**
- Format: `specs/plans/015_dashboard/`
- Main plan with phase summaries + separate phase files for expanded phases
- Example directory:
  - `015_dashboard.md` (main plan with Phase 2 summary)
  - `phase_2_components.md` (expanded phase file)

**Level 2: Stage Expansion**
- Format: `specs/plans/020_refactor/phase_1_analysis/`
- Phase directories with stage subdirectories
- Example directory:
  - `020_refactor.md` (main plan)
  - `phase_1_analysis/` (expanded phase directory)
    - `phase_1_overview.md`
    - `stage_1_codebase_scan.md`

### Expansion Results

When a phase is expanded, the transformation produces:

**Input**: 30-50 line phase outline with tasks and testing description

**Output**: 300-500+ line implementation specification containing:
- Concrete implementation details with code examples
- Specific testing specifications and test cases
- Architecture and design decisions
- Error handling patterns and edge cases
- Performance considerations and optimization strategies

### Parsing Utility

Advanced users can use the progressive parsing utility directly:

```bash
# Detect plan structure level
.claude/lib/plan-core-bundle.sh detect_structure_level <plan-path>

# Check if plan is expanded
.claude/lib/plan-core-bundle.sh is_plan_expanded <plan-path>

# Check if specific phase is expanded
.claude/lib/plan-core-bundle.sh is_phase_expanded <plan-path> <phase-num>

# List expanded phases
.claude/lib/plan-core-bundle.sh list_expanded_phases <plan-path>

# List expanded stages for a phase
.claude/lib/plan-core-bundle.sh list_expanded_stages <plan-path> <phase-num>

# Get plan status
.claude/lib/plan-core-bundle.sh get_status <plan-path>
```

## Standards Discovery

Commands discover and apply project standards through CLAUDE.md and its linked documentation.

### Discovery Process

1. **Locate CLAUDE.md**: Search upward from working directory
2. **Parse Sections**: Extract relevant `[Used by: commands]` sections
3. **Check Subdirectories**: Look for directory-specific CLAUDE.md overrides
4. **Apply Fallbacks**: Use language-specific defaults if standards missing

### Key Standards Resources

| Standard | Resource | Used By |
|----------|----------|---------|
| Code Standards | [Code Standards](../docs/reference/standards/code-standards.md) | /plan, /build |
| Testing Protocols | [Testing Protocols](../docs/reference/standards/testing-protocols.md) | /build |
| Output Formatting | [Output Formatting](../docs/reference/standards/output-formatting.md) | All commands |
| Directory Protocols | [Directory Protocols](../docs/concepts/directory-protocols.md) | /plan, /research, /build |
| Writing Standards | [Writing Standards](../docs/concepts/writing-standards.md) | /plan |
| Adaptive Planning | [Adaptive Planning Guide](../docs/workflows/adaptive-planning-guide.md) | /expand, /collapse, /build |

### Documentation Standards

All commands produce documentation following these standards:

- **NO emojis** in file content (UTF-8 encoding issues)
- **Unicode box-drawing** for diagrams
- **Clear examples** with syntax highlighting
- **Complete workflows** from start to finish
- **CommonMark** specification
- **Present-focused writing** (no historical markers)

See [Writing Standards](../docs/concepts/writing-standards.md) for comprehensive documentation guidelines.

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
- **Git**: Rely on Git history to undo changes
- **Documented**: Track what was done for summaries

### Output
- **Structured**: Use consistent formats (JSONL, markdown)
- **Traceable**: Include timestamps and context
- **Comprehensive**: Provide complete information concisely
- **Commit**: Commit changes with a descriptive message

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

**Primary commands** (e.g., `/build`, `/plan`) appear at the root level with their dependent commands nested below. **Dependent commands** can appear under multiple parents if referenced by multiple primary commands.

### Documentation

- [Neovim Claude Integration](../../nvim/lua/neotex/plugins/ai/claude/README.md) - Integration overview
- [Commands Picker](../../nvim/lua/neotex/plugins/ai/claude/commands/README.md) - Picker documentation
- [Picker Implementation](../../nvim/lua/neotex/plugins/ai/claude/commands/picker.lua) - Source code

## Navigation

### Command Definitions
- [build.md](build.md) - Build from plan execution
- [collapse.md](collapse.md) - Phase/stage collapse (Level 1 to 0, Level 2 to 1)
- [convert-docs.md](convert-docs.md) - Document format conversion
- [debug.md](debug.md) - Debug-focused workflow with root cause analysis
- [errors.md](errors.md) - Query and display error logs
- [expand.md](expand.md) - Phase/stage expansion (Level 0 to 1, Level 1 to 2)
- [optimize-claude.md](optimize-claude.md) - CLAUDE.md optimization analysis
- [plan.md](plan.md) - Research and create implementation plans
- [repair.md](repair.md) - Error analysis and repair planning
- [research.md](research.md) - Research-only workflow for reports
- [revise.md](revise.md) - Research and revise existing plans
- [setup.md](setup.md) - CLAUDE.md setup and optimization

### Related
- [Parent Directory](../README.md)
- [Agents](../agents/README.md) - Agents used by commands
- [Skills](../skills/README.md) - Model-invoked capabilities
- [Specs](../specs/README.md) - Command outputs
- [Documentation](../docs/README.md) - Guides and references
- [Skills Authoring Standards](../docs/reference/standards/skills-authoring.md) - Skills compliance
