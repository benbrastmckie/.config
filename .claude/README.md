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
│   └── shared/         Agent protocols (error, invocation, logging)
├── checkpoints/         Workflow state for interruption recovery
├── commands/            Slash commands for workflows
├── data/                Runtime data (gitignored)
│   ├── agents/         Agent runtime data and metrics
│   ├── checkpoints/    Workflow state persistence
│   ├── commands/       Command execution tracking
│   ├── logs/           Debug and hook execution logs
│   ├── metrics/        Command performance tracking (JSONL)
│   └── templates/      Template usage data
├── docs/                Integration guides and standards
├── hooks/               Event-driven automation scripts
├── lib/                 Utility libraries and shared functions
├── specs/               Plans, reports, summaries (gitignored)
│   ├── plans/          Implementation plans
│   ├── reports/        Research and investigations
│   ├── standards/      Command templates and protocols
│   └── summaries/      Implementation summaries
├── templates/           Reusable workflow templates (YAML)
├── tests/               Test suites for system validation
├── tts/                 Voice notification system
└── settings.local.json  Hook and permission configuration
```

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

**Location**: `templates/` | **See**: [templates/README.md](templates/README.md) | [Template Guide](docs/template-system-guide.md)
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

**Location**: `checkpoints/` | **See**: [checkpoints/README.md](checkpoints/README.md)

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
- [checkpoints/](checkpoints/README.md) - Workflow state persistence
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
