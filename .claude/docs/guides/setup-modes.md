# Setup Command Modes

This document describes the various modes and options available for the `/setup` command.

## Command Syntax

```bash
/setup [project-directory] [options]
```

## Available Modes

### 1. Basic Setup Mode (Default)
Creates or updates CLAUDE.md with project configuration.

```bash
/setup
/setup /path/to/project
```

### 2. Cleanup Mode
Optimizes CLAUDE.md by extracting sections to auxiliary files.

```bash
/setup --cleanup
/setup --cleanup --dry-run  # Preview changes without applying
```

### 3. Validation Mode
Validates CLAUDE.md setup and checks all linked standards files.

```bash
/setup --validate
```

### 4. Analysis Mode
Analyzes CLAUDE.md against standards and best practices.

```bash
/setup --analyze
```

### 5. Enhancement Mode
Automatically discovers project documentation and enhances CLAUDE.md.

```bash
/setup --enhance-with-docs
```

### 6. Report-Driven Updates
Applies specific recommendations from a research report.

```bash
/setup --apply-report /path/to/report.md
```

## Combined Modes

Modes can be combined for comprehensive setup:

```bash
# Full setup with validation and enhancement
/setup --validate --enhance-with-docs

# Cleanup and analyze in one pass
/setup --cleanup --analyze

# Dry-run before actual cleanup
/setup --cleanup --dry-run
```

## See Also

- [Setup Command Guide](./setup-command-guide.md) - Detailed usage guide
- [Command Development Guide](./command-development-guide.md) - Command authoring patterns
- [CLAUDE.md Structure](../concepts/directory-protocols.md) - Project configuration standards
