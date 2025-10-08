# Claude Code Configuration Directory

State-of-the-art agentic workflow system for Claude Code. All 5 phases of advanced capabilities complete (Plan 019), providing comprehensive multi-agent coordination, observability, resilience, and continuous improvement.

## Purpose

This directory implements a complete agentic workflow ecosystem:

- **Commands** - 26 slash commands for development workflows
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
├── commands/            26 slash commands for workflows
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

**Artifact Picker Coverage**: All directories above are accessible through the Neovim artifact picker, which provides categorical organization, README synchronization, and batch loading capabilities for comprehensive artifact management.

## Core Capabilities

### Commands (26 Workflows)
Comprehensive slash command system for all development workflows:
- **Primary**: `/implement`, `/plan`, `/plan-wizard`, `/report`, `/test`, `/orchestrate`
- **Templates**: `/plan-from-template` (60-80% faster plan creation)
- **Analysis**: `/analyze`, `/refactor`, `/debug`
- **Structure**: `/expand`, `/collapse` (progressive plan organization)
- **Utilities**: `/list`, `/update`, `/document`, `/setup`

**Location**: `commands/` | See [commands/README.md](commands/README.md)

### Agents (8 Specialists)
Focused AI assistants with restricted tool access and clear responsibilities:
- **code-writer**, **code-reviewer** - Implementation and quality
- **test-specialist**, **debug-specialist** - Testing and troubleshooting
- **doc-writer**, **research-specialist** - Documentation and research
- **plan-architect**, **metrics-specialist** - Planning and analysis

**Location**: `agents/` | See [agents/README.md](agents/README.md)

### Templates (Workflow Acceleration)
Reusable plan templates with variable substitution:
- CRUD features, API endpoints, refactoring patterns
- Add custom templates directly to `templates/` directory
- 60-80% faster than manual planning
- Simple variables, conditionals, and array iteration
- Use `/plan-from-template` command

**Location**: `templates/` | See [templates/README.md](templates/README.md) | [Template Guide](docs/template-system-guide.md)

### Metrics (Performance Tracking)
Command execution metrics for performance analysis:
- Monthly JSONL logs of command duration and status
- Post-command hook integration
- Manual analysis via JSONL processing tools
- Foundation for future analytics dashboard

**Location**: `data/metrics/` | See [hooks/post-command-metrics.sh](hooks/post-command-metrics.sh)

### Checkpoints (Resilience)
Workflow state persistence for interruption recovery:
- Auto-save at phase boundaries
- Resume interrupted workflows
- 7-day automatic cleanup
- Failed workflow archival

**Location**: `checkpoints/` | See [checkpoints/README.md](checkpoints/README.md)

### Hooks (Automation)
Event-driven scripts for lifecycle automation:
- **Stop**: Metrics collection, TTS notifications
- **Notification**: Permission request alerts
- Always non-blocking, asynchronous execution

**Location**: `hooks/` | **Config**: `settings.local.json` | See [hooks/README.md](hooks/README.md)

### TTS (Voice Notifications)
Uniform voice notifications: "directory, branch" format
- 2 categories: completion, permission
- Single unified voice configuration
- Silent command support
- Debug logging available

**Location**: `tts/` | See [tts/README.md](tts/README.md)

### Metrics (Performance Tracking)
100% command execution capture (achieved in Phase 1):
- Monthly JSONL files with timestamp, operation, duration, status
- Easy analysis with jq
- Non-intrusive collection via hooks

**Location**: `metrics/` | See [metrics/README.md](metrics/README.md)

### Artifacts (Context Management)
Lightweight reference system for 60-80% context reduction:
- Research outputs stored separately
- Passed by reference, not content
- Automatic cleanup and organization
- Comprehensive artifact picker with 11 categories
- Load All operation syncs all artifact types
- README coverage for all .claude/ directories

**Location**: `specs/artifacts/` | See [specs/artifacts/README.md](specs/artifacts/README.md)
**Picker**: Neovim integration provides visual artifact browser with categorical organization

### Utilities (Supporting Scripts)
Core utilities for all subsystems:
- Checkpoint management and state persistence
- Template parsing and variable substitution
- Adaptive planning triggers and logging
- Error analysis and complexity assessment
- Progressive plan structure parsing

**Location**: `lib/` | See [lib/UTILS_README.md](lib/UTILS_README.md)

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
│ /command [args] or natural language request                │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ Learning System                                             │
│ Check for similar workflows → recommendations              │
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
│ • Metrics collection (100% capture)                         │
│ • TTS notification                                          │
│ • Learning data capture                                     │
└─────────────────────────────────────────────────────────────┘
```

### Key Achievements (Plan 019)

**Phase 1**: Critical Fixes & Foundation
- ✅ 100% metrics capture (vs 9% baseline)
- ✅ Extended thinking mode integration
- ✅ Retry logic for agents
- ✅ Artifact system foundation

**Phase 2**: Observability & Artifacts
- ✅ 60-80% context reduction via artifacts
- ✅ Agent performance tracking
- ✅ `/analyze-agents` command

**Phase 3**: Resilience & Error Handling
- ✅ Workflow checkpointing
- ✅ Enhanced error messages
- ✅ Graceful degradation
- ✅ Resume capability

**Phase 4**: Efficiency Enhancements
- ✅ Dynamic agent selection
- ✅ Real-time progress streaming
- ✅ Intelligent parallelization
- ✅ `/plan-wizard` interactive planning

**Phase 5**: Advanced Capabilities
- ✅ Workflow templates (60-80% faster)
- ✅ Agent collaboration protocol
- ✅ Adaptive replanning system
- ✅ `/analyze` command

**Result**: Complete agentic workflow system with template acceleration

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
# List available templates
ls .claude/templates/*.yaml

# Use template for 60-80% faster planning
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

## Documentation Standards

All documentation follows these standards:

- **NO emojis** in file content (UTF-8 encoding issues)
- **Unicode box-drawing** for diagrams (┌ ┐ └ ┘ ─ │ ├ ┤ ┬ ┴ ┼)
- **Clear navigation links** between related documents
- **Code examples** with proper syntax highlighting
- **CommonMark specification** compliance

See `/home/benjamin/.config/nvim/docs/GUIDELINES.md` for complete documentation standards.

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
tail -f .claude/data/logs/tts.log                         # Monitor activity
```

**Agent performance analysis**:
```bash
/analyze agents                                      # View agent metrics
cat .claude/agents/agent-registry.json | jq         # Check registry
```

**Checkpoint not resuming**:
```bash
ls .claude/data/checkpoints/*.json                        # List checkpoints
cat .claude/data/checkpoints/latest.json | jq             # Inspect state
```

## Navigation

### Core Subsystems
- [agents/](agents/README.md) - 8 specialized AI assistants
- [checkpoints/](checkpoints/README.md) - Workflow state persistence
- [commands/](commands/README.md) - 26 slash commands
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

### Parent
- [← .config/](../README.md) - Parent configuration directory

## Related Documentation

- [CLAUDE.md](/home/benjamin/.config/CLAUDE.md) - Project configuration index
- [nvim/CLAUDE.md](/home/benjamin/.config/nvim/CLAUDE.md) - Neovim standards
- [nvim/docs/GUIDELINES.md](/home/benjamin/.config/nvim/docs/GUIDELINES.md) - Development guidelines
