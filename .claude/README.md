# Claude Code Configuration Directory

Comprehensive workflow system for Claude Code providing multi-agent coordination, event automation, and artifact management.

## Access and Navigation

**Neovim Integration**: All artifacts in this directory are accessible through a visual picker in Neovim.
- **Keybinding**: `<leader>ac`
- **Command**: `:ClaudeCommands`
- **Quick Actions**: `<CR>` to execute/edit, `<C-u>`/`<C-d>` to scroll preview, `<C-l>` to load locally
- **Documentation**: See [Neovim Integration](#neovim-integration) section below

## Purpose

This directory provides a complete development workflow ecosystem:

- **Commands** - Slash commands for development workflows
- **Agents** - Specialized AI assistants with focused capabilities
- **Templates** - Reusable workflow patterns with variable substitution
- **Hooks** - Event-driven automation for metrics and notifications
- **Checkpoints** - Workflow state persistence and resume capability
- **TTS** - Voice notifications with uniform messaging
- **Metrics** - Command execution tracking and performance analysis
- **Artifacts** - Lightweight context management system
- **Utilities** - Supporting scripts for all subsystems

## Directory Structure

```
.claude/
├── agents/              Specialized AI assistant definitions
│   ├── prompts/        Agent evaluation templates
│   ├── shared/         Agent protocols (error, invocation, logging)
│   └── templates/      Reusable agent templates (sub-supervisor, etc.)
├── checkpoints/         Workflow state for interruption recovery
├── commands/            Slash commands for workflows
│   └── templates/      Plan templates (YAML) for /plan-from-template
├── data/                Runtime data (gitignored)
│   ├── agents/         Agent runtime data and metrics
│   ├── checkpoints/    Workflow state persistence
│   ├── commands/       Command execution tracking
│   ├── logs/           Debug and hook execution logs
│   ├── metrics/        Command performance tracking (JSONL)
│   └── templates/      Template usage data
├── docs/                Integration guides and standards
├── examples/            Workflow demonstration scripts
├── hooks/               Event-driven automation scripts
├── lib/                 Utility libraries and shared functions
├── scripts/             System management and validation utilities
├── specs/               Plans, reports, summaries (gitignored)
│   ├── plans/          Implementation plans
│   ├── reports/        Research and investigations
│   ├── standards/      Command templates and protocols
│   └── summaries/      Implementation summaries
├── tests/               Test suites for system validation
├── tts/                 Voice notification system
├── utils/               Specialized helper utilities
└── settings.local.json  Hook and permission configuration
```

## Organization Principles

The directory structure follows clear separation of concerns:

1. **Templates Organization**:
   - **agents/templates/** - Agent behavioral templates (sub-supervisor-template.md)
   - **commands/templates/** - Plan templates for /plan-from-template (YAML files)
   - These serve different purposes and should not be confused

2. **Executable vs Sourced**:
   - **scripts/** - Standalone CLI tools (validate-links.sh, migrate-*.sh)
   - **lib/** - Sourced function libraries (plan-parsing.sh, error-handling.sh)
   - **utils/** - Specialized helpers bridging the two

3. **Documentation Requirements**:
   - Every directory must have a README.md
   - READMEs should document purpose, characteristics, and when to use
   - Cross-reference related directories for clarity

4. **File Placement Decision Matrix**:
   - See [lib/README.md - Decision Matrix](lib/README.md#decision-matrix-when-to-use-lib-vs-scripts) for lib/ vs scripts/
   - See [scripts/README.md - Decision Matrix](scripts/README.md#decision-matrix-when-to-use-scripts) for complete guidelines

## Directory Roles

### lib/ - Sourced Utility Libraries
**Purpose**: Modular bash functions sourced by commands, agents, and other utilities

**Characteristics**:
- Contains `.sh` files with reusable bash functions
- Sourced via `source "$CLAUDE_PROJECT_DIR/.claude/lib/utility.sh"`
- Used for logic extraction and code reuse
- Examples: plan parsing, checkpoint management, error handling

**When to Use**: Shared functionality used by multiple commands or agents

**Documentation**: See [lib/README.md](lib/README.md) for complete function inventory

---

### utils/ - Specialized Helper Utilities
**Purpose**: Specialized helper utilities for specific operational tasks

**Characteristics**:
- Can be executed directly or sourced as functions
- Bridge between general-purpose lib/ and task-specific scripts/
- Provide compatibility interfaces and specialized functionality
- Examples: parse-adaptive-plan.sh (compatibility shim), show-agent-metrics.sh

**Difference from lib/**: utils/ are specialized helpers, lib/ are general-purpose functions

**Documentation**: See [utils/README.md](utils/README.md)

---

### scripts/ - System Management Utilities
**Purpose**: Standalone operational scripts for system management and validation

**Characteristics**:
- Task-specific executables for maintenance and analysis
- Include CLI argument parsing and formatted output
- System-level operations (migration, validation, metrics)
- Examples: migrate_to_topic_structure.sh, validate_migration.sh, context_metrics_dashboard.sh

**Difference from lib/**: scripts/ are standalone executables, lib/ are sourced functions

**Documentation**: See [scripts/README.md](scripts/README.md)

---

### examples/ - Workflow Demonstrations
**Purpose**: End-to-end workflow demonstration scripts

**Characteristics**:
- Self-contained runnable examples
- Demonstrate complete workflow patterns
- Show integration between system components
- Examples: artifact_creation_workflow.sh

**Use Case**: Learning system capabilities and workflow patterns

**Documentation**: See [examples/README.md](examples/README.md)

---

### commands/ - Slash Command Prompts
**Purpose**: User-invokable slash command definitions (markdown files)

**Characteristics**:
- Contains `.md` files defining slash commands
- Invoked by user via `/command-name` syntax
- May source lib/ utilities for implementation
- Frontmatter specifies allowed tools and metadata
- Examples: `/implement`, `/plan`, `/orchestrate`

**Structure**: Commands can reference shared documentation in `commands/shared/`

**Documentation**: See [commands/README.md](commands/README.md)

---

### agents/ - AI Assistant Behavioral Guidelines
**Purpose**: Agent prompt definitions invoked programmatically by commands

**Characteristics**:
- Contains `.md` files with agent behavioral prompts
- Invoked via Task tool by commands (not directly by users)
- Define agent behavior, tools, constraints, and objectives
- Frontmatter specifies tool access and metadata
- Examples: code-writer, test-specialist, research-specialist

**Structure**: Agents can reference shared protocols in `agents/shared/`

**Documentation**: See [agents/README.md](agents/README.md)

---

### data/ - Runtime Data (gitignored)
**Purpose**: Generated data, logs, and state files not committed to repository

**Characteristics**:
- All subdirectories are gitignored
- Contains: checkpoints, logs, metrics, agent data, template usage
- Organized by data type and purpose
- Cleaned up automatically based on age and type

**Subdirectories**:
- `checkpoints/` - Workflow state for resume capability
- `logs/` - Debug logs, hook execution logs, TTS logs
- `metrics/` - Command performance tracking (JSONL)
- `agents/` - Agent runtime data and performance metrics
- `templates/` - Template usage statistics

**Important**: Never reference data/ files in committed documentation

---

### templates/ - Plan Templates (YAML)
**Purpose**: Reusable plan structures with variable substitution

**Characteristics**:
- Contains `.yaml` files with template definitions
- Used by `/plan-from-template` and `/plan-wizard` commands
- Support variables, conditionals, and array iteration
- Categories: backend, feature, refactoring, testing, documentation

**Structure**: Variables section + plan structure with placeholders

**Documentation**: See [templates/README.md](templates/README.md)

---

### docs/ - Integration Guides (markdown)
**Purpose**: Documentation about system architecture, standards, and usage

**Characteristics**:
- Contains `.md` files for reference documentation
- Committed to repository (unlike specs/)
- Describes system behavior and patterns
- Examples: command-patterns.md, template-system-guide.md

**Difference from specs/**: docs/ is committed documentation, specs/ is gitignored working artifacts

---

### specs/ - Working Artifacts (gitignored)
**Purpose**: Local working artifacts (plans, reports, summaries) not committed to repository

**Characteristics**:
- All subdirectories and contents are gitignored
- Contains: implementation plans, research reports, summaries
- Organized with incremental numbering (001, 002, 003...)
- Location can be at project root or in subdirectories

**Subdirectories**:
- `plans/` - Implementation plans (progressive structure levels L0/L1/L2)
- `reports/{topic}/` - Research reports organized by topic
- `summaries/` - Implementation summaries linking plans to code

**Important**: specs/ are local working artifacts only, never commit these to git

---

### hooks/ - Event Automation Scripts
**Purpose**: Event-driven scripts triggered by lifecycle events

**Characteristics**:
- Contains bash scripts triggered by Claude Code events
- Registered in `settings.local.json`
- Always non-blocking and asynchronous
- Examples: post-command-metrics.sh, tts-notification.sh

**Active Events**: Stop (completion), Notification (permission requests)

**Documentation**: See [hooks/README.md](hooks/README.md)

---

### tests/ - System Test Suites
**Purpose**: Test suites for validating system functionality

**Characteristics**:
- Contains bash test scripts (`test_*.sh`)
- Run via `./run_all_tests.sh`
- Categories: utilities, commands, integration, adaptive planning
- Coverage target: ≥80% for modified code

**Documentation**: See [tests/README.md](tests/README.md)

---

### checkpoints/ - Legacy Location (deprecated)
**⚠️ Deprecated**: Checkpoint files have been moved to `data/checkpoints/`

Checkpoints should now be stored in `data/checkpoints/` which is gitignored and organized with other runtime data.

---

### tts/ - Voice Notification System
**Purpose**: Text-to-speech notification system with configurable voices

**Characteristics**:
- Contains TTS dispatcher, configuration, and library scripts
- Uniform "directory, branch" message format
- Supports completion and permission notification categories
- Debug logging available

**Documentation**: See [tts/README.md](tts/README.md)

---

## Phase 7: Modular Architecture

### Modular Design Principles

The `.claude/` directory implements three key patterns for maintainability and scalability:

**Reference-Based Composition**: Commands reference shared documentation files instead of duplicating content, reducing file sizes by 28-58% while maintaining clarity.

**Consolidated Utilities**: Utility libraries merge overlapping functionality (plan-core-bundle.sh consolidates 3 planning utilities = 1,159 lines, unified-logger.sh consolidates 2 loggers = 717 lines).

**Progressive Organization**: Plans use organic structure evolution (L0→L1→L2) based on actual complexity, avoiding premature organization.

### Command → Shared Documentation References

Commands now use a reference-based composition pattern where detailed documentation is extracted to `commands/shared/` files:

```
orchestrate.md (850 lines, 68.8% reduction)
  ├─→ shared/workflow-phases.md (1,903 lines)
  ├─→ shared/setup-modes.md (406 lines)
  ├─→ shared/bloat-detection.md (266 lines)
  └─→ shared/extraction-strategies.md (348 lines)

implement.md (498 lines, 49.5% reduction)
  ├─→ shared/phase-execution.md (383 lines)
  ├─→ shared/implementation-workflow.md (152 lines)
  └─→ shared/revise-auto-mode.md (434 lines)

setup.md (375 lines, 58.8% reduction)
revise.md (406 lines, 53.8% reduction)
```

**Benefits**:
- **Reduced Duplication**: Common patterns documented once, referenced everywhere
- **Consistent Updates**: Update shared file once, all commands benefit
- **Improved Navigation**: Command summaries + deep-dive links
- **Maintainability**: Single source of truth for each concept

### Utility Consolidation

Planning utilities, loggers, and base functions have been consolidated:

```
lib/plan-core-bundle.sh (1,159 lines)
  ├─ Consolidates: parse-plan-core.sh + plan-structure-utils.sh + plan-metadata-utils.sh
  └─ Used by: implement, expand, collapse, revise (4 commands)

lib/unified-logger.sh (717 lines)
  ├─ Consolidates: adaptive-planning-logger.sh + conversion-logger.sh
  └─ Used by: implement, expand, orchestrate (3 commands)

lib/base-utils.sh (~100 lines)
  ├─ Common utilities: error(), warn(), info(), debug(), require_*()
  └─ Eliminates 4 duplicate error() functions across utilities
```

**Benefits**:
- Simplified imports: 3 planning utilities → 1 bundle, 2 loggers → 1 unified
- Eliminated circular dependencies via zero-dependency base-utils.sh
- Consistent error handling and logging interfaces
- Backward compatibility maintained via wrapper files

### Phase 7 Results

| Metric | Before | After | Reduction |
|--------|--------|-------|-----------|
| orchestrate.md | 2,720 lines | 850 lines | 68.8% (1,870 lines) |
| implement.md | 987 lines | 498 lines | 49.5% (489 lines) |
| setup.md | 911 lines | 375 lines | 58.8% (536 lines) |
| revise.md | 878 lines | 406 lines | 53.8% (472 lines) |
| **Total Command Reduction** | **5,496 lines** | **2,129 lines** | **61.3% (3,367 lines saved)** |

**New Shared Files Created**:
- `commands/shared/`: 9 files (~2,447 lines total reusable documentation)
- `lib/`: 3 consolidated utilities (plan-core-bundle.sh, unified-logger.sh, base-utils.sh)

**Commands Updated**: 7 commands now use consolidated utilities (implement, expand, collapse, orchestrate, revise, shared documentation files)

---

## Core Capabilities

### Commands

Comprehensive slash command system for all development workflows:
- **Primary**: `/implement`, `/plan`, `/plan-wizard`, `/report`, `/test`, `/orchestrate`
- **Templates**: `/plan-from-template` for accelerated plan creation
- **Analysis**: `/analyze`, `/refactor`, `/debug`
- **Structure**: `/expand`, `/collapse` for progressive plan organization
- **Modification**: `/revise` for plan/report updates (⚠️ `/update` deprecated)
- **Utilities**: `/list`, `/document`, `/setup`

**Recent**: `/update` deprecated (2025-10-10) - use `/revise` instead for all content modifications

**Location**: `commands/` | **See**: [commands/README.md](commands/README.md)
**Neovim**: Browse via `<leader>ac` → [Commands] section

### Agents

Focused AI assistants with restricted tool access and clear responsibilities:
- **code-writer**, **code-reviewer** - Implementation and quality
- **test-specialist**, **debug-specialist** - Testing and troubleshooting
- **doc-writer**, **research-specialist** - Documentation and research
- **plan-architect**, **metrics-specialist** - Planning and analysis

**Location**: `agents/` | **See**: [agents/README.md](agents/README.md)
**Neovim**: Browse via `<leader>ac` → [Agents] section, shows cross-references to parent commands

### Templates (Workflow Acceleration)

Reusable plan templates with variable substitution:
- CRUD features, API endpoints, refactoring patterns
- Add custom templates directly to `templates/` directory
- Simple variables, conditionals, and array iteration
- Use `/plan-from-template` command

**Location**: `templates/` | **See**: [templates/README.md](templates/README.md)
**Neovim**: Browse via `<leader>ac` → [Templates] section

### Hooks (Event Automation)

Event-driven scripts for lifecycle automation:
- **Stop**: Metrics collection, TTS notifications
- **Notification**: Permission request alerts
- Always non-blocking, asynchronous execution

**Location**: `hooks/` | **Config**: `settings.local.json` | **See**: [hooks/README.md](hooks/README.md)
**Neovim**: Browse via `<leader>ac` → [Hook Events] section, organized by event type

### TTS (Voice Notifications)

Uniform voice notifications with "directory, branch" format:
- 2 categories: completion, permission
- Single unified voice configuration
- Silent command support
- Debug logging available

**Location**: `tts/` | **See**: [tts/README.md](tts/README.md)
**Neovim**: Browse via `<leader>ac` → [TTS Files] section

### Metrics (Performance Tracking)

Command execution metrics for performance analysis:
- Monthly JSONL files with timestamp, operation, duration, status
- Post-command hook integration
- Easy analysis with jq
- Non-intrusive collection

**Location**: `data/metrics/` | **See**: [hooks/post-command-metrics.sh](hooks/post-command-metrics.sh)

### Checkpoints (Workflow Resilience)

Workflow state persistence for interruption recovery:
- Auto-save at phase boundaries
- Resume interrupted workflows
- 7-day automatic cleanup
- Failed workflow archival

**Location**: `data/checkpoints/` | **See**: [data/checkpoints/README.md](data/checkpoints/README.md)

### Artifacts (Context Management)

Lightweight reference system for context reduction:
- Research outputs stored separately
- Passed by reference, not content
- Automatic cleanup and organization

**Location**: `specs/artifacts/` | **See**: [specs/artifacts/README.md](specs/artifacts/README.md)

### Utilities (Supporting Scripts)

Core utilities for all subsystems:
- Checkpoint management and state persistence
- Template parsing and variable substitution
- Adaptive planning triggers and logging
- Error analysis and complexity assessment
- Progressive plan structure parsing

**Location**: `lib/` | **See**: [lib/UTILS_README.md](lib/UTILS_README.md)
**Neovim**: Browse via `<leader>ac` → [Lib] section

## Configuration

### settings.local.json

Central configuration file for hook registrations and permissions.

**Structure**:
```json
{
  "permissions": {
    "allow": ["Bash(git add:*)", "..."],
    "deny": [],
    "ask": []
  },
  "hooks": {
    "Stop": [...],
    "SessionStart": [...],
    "SessionEnd": [...],
    "SubagentStop": [...],
    "Notification": [...]
  }
}
```

**Active Hook Events**:
- `Stop`: Command completion → metrics collection, TTS notification
- `Notification`: Permission requests → TTS notification

**Other Events**: SessionStart, SessionEnd, SubagentStop available but not currently registered.

## System Architecture

### Complete Workflow Lifecycle

```
┌─────────────────────────────────────────────────────────────┐
│ User Input                                                  │
│ /command [args] or natural language request                 │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ Command Execution                                           │
│ • Templates (if applicable)                                 │
│ • Agent coordination                                        │
│ • Checkpoint saving                                         │
│ • Artifact management                                       │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ Stop Hook                                                   │
│ • Metrics collection                                        │
│ • TTS notification                                          │
└─────────────────────────────────────────────────────────────┘
```

## Usage Examples

### Complete Feature Implementation

```bash
# 1. Research (optional)
/report "Authentication best practices for Lua"

# 2. Create plan (with or without template)
/plan "Implement user authentication" specs/reports/025_auth_research.md
# OR use template for faster planning:
/plan-from-template crud-feature

# 3. Implement with auto-resume
/implement
# System will auto-detect incomplete plan and resume, or start fresh

# 4. Analyze results
/analyze agents  # Check agent performance
```

### Interactive Planning

```bash
# Use plan wizard for guided plan creation
/plan-wizard
# → Interactive prompts for feature description
# → Component and scope analysis
# → Optional research topic identification
# → Complexity assessment
# → Integration with /plan command
```

### Using Templates

```bash
# List available templates (or use Neovim picker: <leader>ac → [Templates])
ls .claude/templates/*.yaml

# Use template for accelerated planning
/plan-from-template crud-feature
# → Prompts for: entity_name, fields, use_auth, database_type
# → Generates complete plan with phases and tests
```

## Quick Reference

### Most Used Commands

```bash
/implement               # Execute plan (auto-resumes)
/plan <description>      # Create implementation plan
/plan-wizard            # Interactive guided planning
/plan-from-template     # Create plan from template
/report <topic>         # Research and document
/test <target>          # Run project tests
/orchestrate <workflow> # Multi-agent coordination
/analyze agents         # View agent performance
```

### Configuration Files

```bash
.claude/settings.local.json      # Hook registration, permissions
.claude/tts/tts-config.sh        # TTS voice settings
CLAUDE.md                        # Project standards and protocols
```

### Monitoring & Analysis

```bash
# View metrics
cat .claude/data/metrics/$(date +%Y-%m).jsonl | jq

# Check TTS activity
tail -f .claude/data/logs/tts.log

# Analyze agent performance
/analyze-agents

# View workflow patterns
/analyze-patterns
```

## Neovim Integration

All artifacts in this directory are accessible through a comprehensive Telescope picker in Neovim, providing visual browsing and management of all Claude Code components.

### Accessing the Picker

- **Keybinding**: `<leader>ac` in normal mode
- **Command**: `:ClaudeCommands`
- **Implementation**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/`

### Picker Categories

The picker organizes artifacts into categorical sections:

**[Commands]** - All slash commands (`.md` files)
- Hierarchical display showing primary commands and dependencies
- Command metadata preview (description, arguments, allowed tools)

**[Agents]** - AI specialists (`.md` files)
- Standalone agents section
- Cross-references showing which commands use each agent
- Agent capabilities and tool access preview

**[Hook Events]** - Event-triggered scripts (`.sh` files)
- Organized by event type (Stop, SessionStart, etc.)
- Shows all hooks registered for each event
- Local indicator if any hook is project-local

**[TTS Files]** - Voice notification system (`.sh` files)
- Config, dispatcher, and library files
- Role indicators (config, dispatcher, library)

**[Templates]** - Workflow templates (`.yaml` files)
- Template descriptions extracted from YAML
- Variable definitions preview

**[Lib]** - Utility libraries (`.sh` files)
- Descriptions extracted from file headers
- Sourcing and usage examples

**[Docs]** - Integration guides (`.md` files)
- Quick reference documentation
- Standards and protocol guides

### Key Features

**Direct Actions**:
- Press `<CR>` to insert commands into Claude Code or edit files
- Commands insert into terminal, all others open for editing

**Local/Global Management**:
- `*` prefix shows project-local artifacts (in current project's `.claude/`)
- No prefix indicates global artifacts (in `~/.config/.claude/`)
- `<C-l>` to copy global artifacts to local project
- `<C-g>` to update local artifacts from global versions
- `<C-s>` to save local customizations to global

**Preview Navigation**:
- `<C-u>`/`<C-d>` for half-page preview scrolling
- `<C-f>`/`<C-b>` for full-page preview scrolling
- Native Telescope scrolling (no focus switching required)
- Works from picker without buffer errors

**README Preview**:
- Category headings display associated README.md files
- Provides contextual help without leaving picker
- Scroll through documentation with `<C-u>`/`<C-d>`

**Universal Operations**:
- `<C-e>` to edit any artifact type
- `[Load All Artifacts]` entry for batch synchronization
- Single-press `<Esc>` to close picker

### Quick Actions Reference

```vim
" Open artifact picker
<leader>ac
:ClaudeCommands

" Navigation
j/k                  " Move selection
/pattern             " Fuzzy search

" Actions
<CR>                 " Insert command or edit file
<C-u>/<C-d>          " Scroll preview (half page)
<C-f>/<C-b>          " Scroll preview (full page)

" Artifact Management
<C-l>                " Load artifact locally
<C-g>                " Update from global version
<C-s>                " Save to global
<C-e>                " Edit file

" Other
<C-n>                " Create new command
<Esc>                " Close picker
```

### Documentation Links

- [Neovim Claude Integration](../nvim/lua/neotex/plugins/ai/claude/README.md) - Integration overview
- [Commands Picker Documentation](../nvim/lua/neotex/plugins/ai/claude/commands/README.md) - Detailed picker reference
- [Picker Implementation](../nvim/lua/neotex/plugins/ai/claude/commands/picker.lua) - Source code

## Documentation Standards

All documentation follows these standards:

- **NO emojis** in file content (UTF-8 encoding issues)
- **Unicode box-drawing** for diagrams (┌ ┐ └ ┘ ─ │ ├ ┤ ┬ ┴ ┼)
- **Clear navigation links** between related documents
- **Code examples** with proper syntax highlighting
- **CommonMark specification** compliance

See `/home/benjamin/.config/nvim/docs/CODE_STANDARDS.md` for complete documentation standards.

## Troubleshooting

### Common Issues

**Metrics not collecting**:
```bash
cat .claude/settings.local.json | jq '.hooks.Stop'  # Verify hook registered
.claude/hooks/post-command-metrics.sh < test.json   # Test manually
```

**TTS not working**:
```bash
grep "TTS_ENABLED=true" .claude/tts/tts-config.sh   # Check enabled
espeak-ng "Test"                                     # Test engine
tail -f .claude/data/logs/tts.log                   # Monitor activity
```

**Agent performance analysis**:
```bash
/analyze agents                                      # View agent metrics
cat .claude/agents/agent-registry.json | jq         # Check registry
```

**Checkpoint not resuming**:
```bash
ls .claude/data/checkpoints/*.json                  # List checkpoints
cat .claude/data/checkpoints/latest.json | jq       # Inspect state
```

**Neovim picker not showing artifacts**:
```bash
# Verify directories exist
ls .claude/commands/ .claude/agents/ .claude/templates/

# Check Neovim integration is loaded
:ClaudeCommands

# Verify keybinding
:nmap <leader>ac
```

## Navigation

### Core Subsystems
- [agents/](agents/README.md) - Specialized AI assistants
- [data/checkpoints/](data/checkpoints/README.md) - Workflow state persistence
- [commands/](commands/README.md) - Slash commands
- [data/](data/README.md) - Runtime logs and metrics (gitignored)
- [docs/](docs/README.md) - Integration guides and standards
- [hooks/](hooks/README.md) - Event automation scripts
- [lib/](lib/UTILS_README.md) - Supporting utilities
- [specs/](specs/README.md) - Plans, reports, summaries (gitignored)
- [templates/](templates/README.md) - Reusable workflow patterns
- [tests/](tests/README.md) - System test suites
- [tts/](tts/README.md) - Voice notification system

### Configuration
- [settings.local.json](settings.local.json) - Hook and permission config

### Related Documentation
- [CLAUDE.md](/home/benjamin/.config/CLAUDE.md) - Project configuration index
- [nvim/CLAUDE.md](/home/benjamin/.config/nvim/CLAUDE.md) - Neovim standards
- [nvim/docs/CODE_STANDARDS.md](/home/benjamin/.config/nvim/docs/CODE_STANDARDS.md) - Development guidelines

### Parent
- [← .config/](../README.md) - Parent configuration directory
