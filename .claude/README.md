# Claude Code Configuration Directory

Centralized configuration and automation system for Claude Code, providing structured workflows, intelligent hooks, metrics collection, and text-to-speech notifications.

## Purpose

This directory contains all Claude Code customizations and extensions:

- **Command definitions** for project workflows
- **Agent definitions** for specialized AI assistants
- **Hook scripts** for event-driven automation
- **TTS integration** for voice notifications
- **Metrics collection** for performance analysis
- **Specifications** for planning and documentation

## Directory Structure

```
.claude/
├── agents/              Agent definitions for specialized tasks
├── commands/            Custom command implementations
├── docs/                Documentation and integration guides
├── hooks/               Event hook scripts for automation
├── logs/                Runtime logs and debug output
├── metrics/             Command execution metrics (JSONL format)
├── specs/               Plans, reports, and implementation summaries
│   ├── plans/          Implementation plans
│   ├── reports/        Research and investigation reports
│   ├── standards/      Project standards and protocols
│   └── summaries/      Implementation summaries
├── tts/                 Text-to-speech configuration and messages
└── settings.local.json  Hook registrations and permissions
```

## Core Components

### Commands
Custom slash commands that extend Claude Code functionality. Each command is defined in a markdown file with metadata, description, and implementation instructions.

**Location**: `commands/`
**Examples**: `/implement`, `/plan`, `/report`, `/test`, `/orchestrate`

See [commands/README.md](commands/README.md) for details.

### Agents
Specialized AI assistants with focused capabilities and tool access. Agents can be invoked by commands for specific subtasks.

**Location**: `agents/`
**Examples**: `code-writer`, `test-specialist`, `doc-writer`, `research-specialist`

See [agents/README.md](agents/README.md) for details.

### Hooks
Event-driven scripts that execute automatically during Claude Code lifecycle events. Hooks enable automation like metrics collection and TTS notifications.

**Location**: `hooks/`
**Registered in**: `settings.local.json`

See [hooks/README.md](hooks/README.md) for details.

### TTS System
Text-to-speech notification system providing voice feedback for workflow events. Categorized notifications with customizable voice characteristics.

**Location**: `tts/`
**Configuration**: `tts/tts-config.sh`

See [tts/README.md](tts/README.md) for details.

### Metrics
Automated collection of command execution metrics for performance analysis and optimization.

**Location**: `metrics/`
**Format**: Monthly JSONL files (YYYY-MM.jsonl)

See [metrics/README.md](metrics/README.md) for details.

### Specifications
Structured documentation including implementation plans, research reports, and summaries.

**Location**: `specs/`
**Subdirectories**: `plans/`, `reports/`, `standards/`, `summaries/`

See [specs/README.md](specs/README.md) for details.

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

**Hook Events**:
- `Stop`: Command completion
- `SessionStart`: Session initialization
- `SessionEnd`: Session termination
- `SubagentStop`: Subagent task completion
- `Notification`: Permission requests and idle alerts

Each hook can register multiple scripts that execute on event trigger.

## Workflow Lifecycle

```
┌─────────────────────────────────────────────────────────────┐
│ User Input                                                  │
│ /command or natural language request                       │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ Command Processing                                          │
│ Custom command or built-in functionality                    │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ Hook: Stop Event                                            │
├─────────────────────────────────────────────────────────────┤
│ • post-command-metrics.sh → Collect execution metrics      │
│ • tts-dispatcher.sh → Voice notification                    │
└─────────────────────────────────────────────────────────────┘
```

## Extension Points

### Adding Custom Commands
1. Create `commands/your-command.md` with metadata and instructions
2. Define allowed tools and dependencies
3. Document standards discovery and usage
4. Test with `/your-command` in Claude Code

### Adding Custom Hooks
1. Create hook script in `hooks/`
2. Make executable: `chmod +x hooks/your-hook.sh`
3. Register in `settings.local.json` under appropriate event
4. Test hook execution with relevant event

### Adding TTS Categories
1. Add category configuration in `tts/tts-config.sh`
2. Implement message generator in `tts/tts-messages.sh`
3. Update dispatcher routing in `hooks/tts-dispatcher.sh`
4. Test with relevant event trigger

## Best Practices

### Command Development
- Follow established patterns from existing commands
- Use standards discovery for CLAUDE.md integration
- Document all parameters and dependencies
- Include usage examples

### Hook Development
- Always exit 0 (non-blocking)
- Run asynchronously when possible
- Handle missing dependencies gracefully
- Log to `.claude/logs/` for debugging

### Agent Design
- Focus on single responsibility
- Define minimal necessary tool access
- Document capabilities clearly
- Test with real use cases

## Documentation Standards

All documentation follows these standards:

- **NO emojis** in file content (UTF-8 encoding issues)
- **Unicode box-drawing** for diagrams (┌ ┐ └ ┘ ─ │ ├ ┤ ┬ ┴ ┼)
- **Clear navigation links** between related documents
- **Code examples** with proper syntax highlighting
- **CommonMark specification** compliance

See `/home/benjamin/.config/nvim/docs/GUIDELINES.md` for complete documentation standards.

## Logs and Debugging

### Log Files
- `logs/hook-debug.log`: Hook execution trace
- `logs/tts.log`: TTS invocation history (when TTS_DEBUG=true)

### Debugging Hooks
1. Check hook execution: `tail -f .claude/logs/hook-debug.log`
2. Verify hook registration: `cat .claude/settings.local.json`
3. Test hook manually: `.claude/hooks/your-hook.sh`

### Debugging TTS
1. Enable debug mode: `TTS_DEBUG=true` in `tts/tts-config.sh`
2. Monitor TTS log: `tail -f .claude/logs/tts.log`
3. Test message generation: `source tts/tts-messages.sh && generate_completion_message`

## Navigation

### Subdirectories
- [agents/](agents/README.md) - Agent definitions
- [commands/](commands/README.md) - Command implementations
- [docs/](docs/README.md) - Documentation and guides
- [hooks/](hooks/README.md) - Hook scripts
- [logs/](logs/README.md) - Runtime logs
- [metrics/](metrics/README.md) - Performance metrics
- [specs/](specs/README.md) - Plans, reports, summaries
- [tts/](tts/README.md) - TTS configuration

### Key Files
- [settings.local.json](#settingslocaljson) - Hook and permission configuration

### Parent
- [← .config/](../README.md) - Parent configuration directory

## Quick Start

### Enable TTS Notifications
```bash
# Edit TTS configuration
nvim .claude/tts/tts-config.sh

# Set TTS_ENABLED=true
# Enable desired categories
# Customize voice parameters

# Test TTS
espeak-ng "Claude ready"
```

### View Metrics
```bash
# Show current month metrics
cat .claude/metrics/$(date +%Y-%m).jsonl | jq

# Analyze command durations
cat .claude/metrics/*.jsonl | jq -s 'group_by(.operation) | map({operation: .[0].operation, avg_ms: (map(.duration_ms) | add / length)})'
```

### Create New Command
```bash
# Create command file
nvim .claude/commands/my-command.md

# Add metadata and implementation
# Test command
# /my-command
```

## Related Documentation

- [CLAUDE.md](/home/benjamin/.config/CLAUDE.md) - Project configuration index
- [nvim/CLAUDE.md](/home/benjamin/.config/nvim/CLAUDE.md) - Neovim standards
- [nvim/docs/GUIDELINES.md](/home/benjamin/.config/nvim/docs/GUIDELINES.md) - Development guidelines
