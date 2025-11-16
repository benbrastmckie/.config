# Commands Directory

Custom slash command definitions for Claude Code. Each command extends Claude's capabilities with specialized workflows for development, documentation, testing, and project management.

**Current Command Count**: 19 active commands

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

### Command Cleanup (2025-11-15)

**Removed Commands** (Clean-break philosophy):
- `/orchestrate` → **Use `/coordinate` instead** (superseded by production-ready replacement)
- `/supervise` → **Use `/coordinate` instead** (reference implementation only)
- All backup files (23 files, 1.4M) → **Use git for version control** (see [Git Recovery Guide](../docs/guides/git-recovery-guide.md))

**Impact**: 48.1% directory reduction (52 → 27 files), 71% disk space reclaimed (2.2M → 640K)

### Command Consolidation (2025-10-10)

**Deprecated Commands**:
- `/update` → **Use `/revise` instead** (consolidated for clarity)

**Why**: `/update` and `/revise` had 70% overlapping functionality, causing user confusion
about when to use which command. All update capabilities have been integrated into
`/revise` for a single, clear command for all content modifications.

### Command Consolidation (2025-10-06)
Consolidated redundant commands for a cleaner interface:
- `/cleanup` → **Removed** (use `/setup --cleanup` instead)
- `/validate-setup` → **Removed** (use `/setup --validate` instead)
- `/analyze-agents` + `/analyze-patterns` → **Removed** (use `/analyze [type]` instead)

### Shared Utilities Integration (2025-10-06)
Commands now reference shared utility libraries in `.claude/lib/`:
- `checkpoint-utils.sh` - Workflow state persistence
- `complexity-utils.sh` - Phase complexity analysis
- `artifact-utils.sh` - Artifact tracking and registry
- `error-utils.sh` - Error classification and recovery
- `adaptive-planning-logger.sh` - Adaptive planning logging

### Phase 7 Modularization (2025-10-15)

**Reference-Based Composition Pattern**: Commands now use a modular documentation architecture where detailed sections are extracted to `commands/shared/` files and referenced via markdown links.

**File Size Reductions**:
- `coordinate.md`: 2,720 → 850 lines (68.8% reduction, 1,870 lines saved)
- `implement.md`: 987 → 498 lines (49.5% reduction, 489 lines saved)
- `setup.md`: 1071 → 311 lines (71.0% reduction, 760 lines saved)
- `revise.md`: 878 → 406 lines (53.8% reduction, 472 lines saved)
- **Total**: 5,496 → 2,129 lines (61.3% reduction, 3,367 lines saved)

**Shared Documentation Files Created** (`commands/shared/`):
- `workflow-phases.md` (1,903 lines) - 5 workflow phases for orchestration
- `phase-execution.md` (383 lines) - Checkpoint, test, commit workflow
- `implementation-workflow.md` (152 lines) - Implementation patterns
- `setup-modes.md` (406 lines) - 5 setup command modes
- `bloat-detection.md` (266 lines) - Bloat detection algorithms
- `extraction-strategies.md` (348 lines) - Extraction preferences
- `standards-analysis.md` (247 lines) - Standards analysis procedures
- `revise-auto-mode.md` (434 lines) - Auto-mode specification
- `revision-types.md` (109 lines) - 5 revision types

**Consolidated Utilities** (`lib/`):
- `plan-core-bundle.sh` (1,159 lines) - Consolidates 3 planning utilities
- `unified-logger.sh` (717 lines) - Consolidates 2 loggers
- `base-utils.sh` (~100 lines) - Common error(), warn(), info() functions

**Benefits**:
- **Reduced Duplication**: Common patterns documented once, referenced everywhere
- **Improved Maintainability**: Update shared file once, all commands benefit
- **Better Navigation**: Command files show summaries, shared files provide details
- **Simplified Imports**: 3 → 1 for planning utils, 2 → 1 for loggers
- **Backward Compatibility**: Wrapper files maintain compatibility during transition

**See**: [commands/shared/README.md](shared/README.md) for shared documentation index

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

#### /research
**Purpose**: Research topics using hierarchical multi-agent pattern

**Usage**: `/research <topic or question>`

**Features**:
- Automatic topic decomposition into 2-4 subtopics
- Parallel research-specialist agents for faster execution (40-60% time savings)
- Hierarchical structure with individual subtopic reports
- Comprehensive OVERVIEW.md synthesis report (ALL CAPS)
- Cross-references between all reports
- Better organization with grouped subdirectories
- Web research integration
- Technology investigation
- Best practices analysis
- Structured markdown output

**Output**: `specs/{NNN_topic}/reports/{NNN_research}/` directory containing:
- Individual subtopic reports: `001_subtopic.md`, `002_subtopic.md`, etc.
- Final synthesis: `OVERVIEW.md` (ALL CAPS, not numbered)

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
- Custom template support (add to `.claude/commands/templates/`)
- 60-80% faster plan creation

**Templates**:
- crud-feature: CRUD operations for entities
- api-endpoint: REST API implementation
- refactoring: Structured code refactoring
- example-feature: Example showing template structure
- Custom templates: Add `.yaml` files to `.claude/commands/templates/` directory

**Output**: `specs/plans/NNN_plan_name.md`

**Custom Templates**:
Add custom templates directly to `.claude/commands/templates/` directory as `.yaml` files.
See `.claude/commands/templates/example-feature.yaml` for template structure.

---

#### /analyze
**Purpose**: Analyze system performance metrics and patterns

**Usage**: `/analyze [type] [search-pattern]`

**Types**:
- `agents` - Agent performance metrics and efficiency
- `patterns` - (Not implemented) Reserved for future pattern analysis
- `all` - Currently equivalent to `agents`

**Features**:
- Agent performance rankings
- Efficiency scoring
- Success rate analysis
- Actionable recommendations

**Output**: Console analysis report

---

### Workflow Commands


#### /revise
**Purpose**: Revise existing implementation plan or research report with new requirements

**Usage**:
- `/revise <revision-details> [context-path1] ...` (revision-first)
- `/revise <artifact-path> <revision-details> [context-path1] ...` (path-first)

**Features**:
- **Plans**: Progressive structure-aware modification, all levels (L0/L1/L2)
- **Reports**: Section-specific targeting, findings updates
- Flexible syntax (revision-first or path-first)
- Research integration for both plans and reports
- Auto-mode for `/implement` integration (plans only)
- No implementation (planning only)

**Artifact Support**: Plans (L0/L1/L2), Reports (single-file)

---

#### /expand phase
**Purpose**: Extract phase to separate file (Level 0 → 1 transition)

**Usage**: `/expand phase <plan-path> <phase-num>`

**Features**:
- On-demand phase extraction
- Automatic directory creation
- Metadata tracking

#### /collapse phase
**Purpose**: Merge phase file back into main plan (Level 1 → 0 transition)

**Usage**: `/collapse phase <plan-path> <phase-num>`

**Features**:
- Content merging
- Directory cleanup
- Metadata updates

---

#### /update ⚠️ DEPRECATED
**Purpose**: ⚠️ DEPRECATED - Use `/revise` instead

**Deprecation Date**: 2025-10-10

**Migration**: Use `/revise` for all plan and report modifications

**Why Deprecated**: 70% functionality overlap with `/revise`. Consolidating to `/revise` provides:
- Clearer command responsibilities (content vs structure)
- Better features (auto-mode, research integration, structure recommendations)
- Single command for all content modifications

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
- `/implement`, `/plan`, `/research`, `/test`, `/coordinate`

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
- `/implement`: Navigates structure level to find and execute phases
- `/list plans`: Shows level indicators [L0], [L1], [L2]
- `/update plan`: Modifies correct files based on expansion status
- `/revise`: Analyzes revision scope to target appropriate file(s)
- `/expand phase`: Extracts phase to separate file (Level 0 → 1)
- `/expand stage`: Extracts stage to separate file (Level 1 → 2)
- `/collapse phase`: Merges phase back into main plan (Level 1 → 0)
- `/collapse stage`: Merges stage back into phase (Level 2 → 1)

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

See [/home/benjamin/.config/nvim/docs/CODE_STANDARDS.md](../../nvim/docs/CODE_STANDARDS.md) for complete standards.

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

" Navigate to /plan command
" Press Return to insert "/plan" in Claude Code
" Or press <C-e> to edit plan.md file
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

**Primary commands** (e.g., `/plan`, `/implement`) appear at the root level with their dependent commands nested below. **Dependent commands** can appear under multiple parents if referenced by multiple primary commands.

### Documentation

- [Neovim Claude Integration](../../nvim/lua/neotex/plugins/ai/claude/README.md) - Integration overview
- [Commands Picker](../../nvim/lua/neotex/plugins/ai/claude/commands/README.md) - Picker documentation
- [Picker Implementation](../../nvim/lua/neotex/plugins/ai/claude/commands/picker.lua) - Source code

## Navigation

### Command Definitions
- [analyze.md](analyze.md) - System analysis (agents, patterns, metrics)
- [debug.md](debug.md) - Issue investigation
- [document.md](document.md) - Documentation updates
- [implement.md](implement.md) - Plan execution
- [list.md](list.md) - List artifacts (plans, reports, summaries)
- [expand-phase.md](expand-phase.md) - Phase expansion (L0→L1)
- [expand-stage.md](expand-stage.md) - Stage expansion (L1→L2)
- [collapse-phase.md](collapse-phase.md) - Phase collapse (L1→L0)
- [collapse-stage.md](collapse-stage.md) - Stage collapse (L2→L1)
- [coordinate.md](coordinate.md) - Multi-agent workflow coordination (production orchestrator)
- [plan.md](plan.md) - Implementation planning
- [plan-wizard.md](plan-wizard.md) - Interactive plan creation
- [plan-from-template.md](plan-from-template.md) - Template-based planning
- [refactor.md](refactor.md) - Code analysis
- [research.md](research.md) - Research reports
- [revise.md](revise.md) - Plan revision
- [setup.md](setup.md) - CLAUDE.md setup
- [test.md](test.md) - Test execution
- [test-all.md](test-all.md) - Full test suite

### Related
- [← Parent Directory](../README.md)
- [agents/](../agents/README.md) - Agents used by commands
- [specs/](../specs/README.md) - Command outputs

## Examples

### Running Implementation
```bash
# Create plan (always starts as Level 0)
/plan "Add dark mode toggle to settings"

# Implement Level 0 plan (single file)
/implement specs/plans/007_dark_mode_implementation.md

# Expand complex phase during implementation
/expand phase specs/plans/007_dark_mode.md 2

# Implement Level 1 plan (with expanded phase)
/implement specs/plans/007_dark_mode/

# Or just auto-resume latest incomplete plan
/implement
```

### Research and Plan
```bash
# Research the topic
/research "TTS engine comparison for Linux"

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
/expand phase specs/plans/007_dark_mode.md 2

# Update Level 1 plan (modifies appropriate files)
/update plan specs/plans/015_dashboard/ "Add Phase 9: Performance testing"

# Revise specific phase
/revise "Update Phase 3 complexity to High" specs/plans/015_dashboard/

# Collapse phase to simplify
/collapse phase specs/plans/015_dashboard/ 5
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
