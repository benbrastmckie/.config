# Utility Libraries

## Purpose

Miscellaneous utility functions for git, testing, validation, and other tasks. This directory provides backup and rollback utilities for command files, dependency graph analysis for wave-based execution, test environment detection and protocol generation, git commit utilities, CLAUDE.md optimization, real-time progress dashboard rendering, and agent invocation validation.

## Libraries

### backup-command-file.sh
Command file backup utilities.

**Key Functions:**
- `backup_command()` - Create backup of command file
- `list_backups()` - List available backups

### dependency-analyzer.sh
Dependency graph analysis for wave-based execution.

**Key Functions:**
- `analyze_dependencies()` - Analyze plan dependencies
- `build_wave_structure()` - Build wave execution structure
- `detect_cycles()` - Detect circular dependencies

**Usage:**
```bash
bash "${CLAUDE_PROJECT_DIR}/.claude/lib/util/dependency-analyzer.sh" "$plan_path" > dependency_analysis.json
```

### detect-testing.sh
Test environment detection.

**Key Functions:**
- `is_test_environment()` - Check if running in test environment
- `get_test_mode()` - Get current test mode

### generate-testing-protocols.sh
Test protocol generation.

**Key Functions:**
- `generate_test_protocol()` - Generate test protocol from plan
- `create_test_checklist()` - Create testing checklist

### git-commit-utils.sh
Git commit utilities.

**Key Functions:**
- `create_commit()` - Create git commit
- `get_staged_files()` - Get list of staged files
- `format_commit_message()` - Format commit message

**Usage:**
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/util/git-commit-utils.sh"
create_commit "Add new feature"
```

### optimize-claude-md.sh
CLAUDE.md optimization utilities.

**Key Functions:**
- `optimize_claude_md()` - Optimize CLAUDE.md structure
- `extract_sections()` - Extract sections for optimization

### progress-dashboard.sh
Progress dashboard rendering for real-time visual feedback.

**Key Functions:**
- `detect_terminal_capabilities()` - Detect terminal ANSI support
- `render_dashboard()` - Render complete dashboard
- `initialize_dashboard()` - Initialize by reserving screen space
- `update_dashboard_phase()` - Update phase status
- `clear_dashboard()` - Clear dashboard on completion

**Usage:**
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/util/progress-dashboard.sh"
initialize_dashboard "My Plan" 5
render_dashboard "My Plan" 2 5 '[...]' 323 492 "Running tests" '...' '...'
clear_dashboard
```

**Supported Terminals:** bash with xterm-256color, zsh with color support, tmux, GNOME Terminal, Konsole, iTerm2, Terminal.app

### rollback-command-file.sh
Command file rollback utilities.

**Key Functions:**
- `rollback_command()` - Rollback to previous backup
- `get_latest_backup()` - Get most recent backup

### validate-agent-invocation-pattern.sh
Agent invocation validation.

**Key Functions:**
- `validate_agent_invocation()` - Validate agent invocation pattern
- `check_agent_format()` - Check agent format compliance

## Navigation

- [← Parent Directory](../README.md)
