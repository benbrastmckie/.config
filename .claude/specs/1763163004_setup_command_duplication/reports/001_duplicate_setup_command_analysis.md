# Duplicate /setup Command Analysis

## Executive Summary

The Claude Code autocomplete shows two `/setup` command entries with nearly identical descriptions but different scope labels: "(user)" and "(project)". This creates confusion and indicates that command discovery is reading from multiple sources.

## Problem Statement

When typing `/setup` in Claude Code, users see:

1. `/setup` - "Setup or improve CLAUDE.md with smart extraction, cleanup optimization, standards analysis, and report-driven updates **(user)**"
2. `/setup` - "Setup or improve CLAUDE.md with smart extraction, cleanup optimization, validation, standards analysis, report-driven updates, and automatic documentation enhancement **(project)**"

### Key Observations

1. **Single source file**: Only ONE `setup.md` file exists at `/home/benjamin/.config/.claude/commands/setup.md`
2. **Description mismatch**: The "(user)" version has a shorter description missing "validation" and "automatic documentation enhancement"
3. **Scope labels**: The "(user)" and "(project)" labels suggest command discovery from multiple locations
4. **Current description**: The actual file contains the full description (matching the "project" version)

## Root Cause Analysis

### Hypothesis 1: Multi-Level Command Discovery

Claude Code appears to discover slash commands from multiple locations:

1. **Project-level**: `.claude/commands/` in the current project (labeled "project")
2. **User-level**: Some user-level configuration directory (labeled "user")
3. **System-level**: Possibly built-in commands from the Claude Code installation

### Hypothesis 2: Outdated User-Level Command

Evidence suggests a user-level `/setup` command with an older description exists somewhere in the user's configuration, predating the addition of "validation" and "automatic documentation enhancement" features.

### Investigation Results

**Checked locations**:
- ✓ Project commands: `/home/benjamin/.config/.claude/commands/setup.md` (FOUND - current version)
- ✓ User config: `~/.config/claude-code/` (checked - no commands directory)
- ✓ Plugin directory: `~/.local/share/nvim/lazy/claude-code.nvim/` (checked - no duplicate setup.md)
- ✗ **Missing**: User-level commands directory location unknown

**Metadata analysis**:
```yaml
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, SlashCommand
argument-hint: [project-directory] [--cleanup [--dry-run]] [--validate] [--analyze] [--apply-report <report-path>] [--enhance-with-docs]
description: Setup or improve CLAUDE.md with smart extraction, cleanup optimization, validation, standards analysis, report-driven updates, and automatic documentation enhancement
command-type: primary
dependent-commands: orchestrate
```

No metadata field distinguishes "user" vs "project" scope in the command file itself.

## Description Comparison

### User Version (Outdated)
```
Setup or improve CLAUDE.md with smart extraction, cleanup optimization, standards analysis, and report-driven updates
```

### Project Version (Current)
```
Setup or improve CLAUDE.md with smart extraction, cleanup optimization, validation, standards analysis, report-driven updates, and automatic documentation enhancement
```

### Differences
Missing from user version:
- "validation" (feature added for /setup --validate)
- "automatic documentation enhancement" (--enhance-with-docs flag)

## Impact Assessment

### User Experience Impact
- **Confusion**: Users see two seemingly identical commands
- **Wrong choice**: Selecting "(user)" version may use outdated command logic
- **Autocomplete clutter**: Duplicate entries make command discovery harder

### Technical Impact
- **Maintenance burden**: Two versions must be kept in sync
- **Documentation mismatch**: User documentation may reference features not available in user-level command
- **Testing complexity**: Both versions should theoretically be tested

## Potential User-Level Command Locations

Based on typical configuration patterns, potential locations for user-level commands:

1. `~/.config/claude-code/commands/` (not found)
2. `~/.claude/commands/` (not checked - global user commands)
3. `~/.config/.claude/commands/` (current project, already checked)
4. Built-in to Claude Code binary/service (cannot modify)

## Recommendations

### Short-Term Fix
1. Locate the user-level `/setup` command file
2. Delete or update it to match the project-level version
3. Verify only one entry appears in autocomplete

### Long-Term Solution
1. **Document command discovery hierarchy**: Clarify where Claude Code looks for commands
2. **Version checking**: Implement command version metadata to detect outdated duplicates
3. **Warning system**: Warn users when duplicate commands are found with different descriptions
4. **Migration tooling**: Provide `/cleanup-commands` to remove outdated user-level commands

### Questions to Answer
1. Where does Claude Code store user-level commands?
2. Can user-level commands be disabled or overridden by project-level commands?
3. Should user-level commands be deprecated in favor of project-only commands?
4. How are "(user)" and "(project)" labels determined?

## Next Steps

1. ✅ Consult Claude Code documentation for command discovery hierarchy
2. ✅ Check for hidden `.claude` directories in user home directory
3. ✅ Use process tracing to identify where Claude Code reads command files
4. ✅ Create implementation plan to remove or update the outdated user-level command

## Solution Implemented

**Date**: 2025-11-14

### Root Cause Confirmed

User-level command found at `~/.claude/commands/setup.md` (2206 lines, 63,526 bytes) - severely outdated pre-refactoring version from October 2, 2025.

### Command Discovery Hierarchy (Documented)

Claude Code searches TWO locations for custom slash commands:

1. **Project-level**: `.claude/commands/` (repository root)
   - Shows "(project)" label in autocomplete
   - Team-shared, version-controlled

2. **Personal-level**: `~/.claude/commands/` (user home directory)
   - Shows "(user)" label in autocomplete
   - Individual, cross-project use

**Critical Finding**: "Conflicts between user and project level commands are not supported" - both versions appear in autocomplete if they share the same name.

### Solution Applied

1. ✅ Created backup: `~/.claude/commands/setup.md.backup-20251114`
2. ✅ Removed outdated user-level command: `rm ~/.claude/commands/setup.md`
3. ✅ Verified project-level command intact with all features
4. ✅ Created troubleshooting guide: `.claude/docs/troubleshooting/duplicate-commands.md`

### Version Comparison

| Feature | User-level (OLD) | Project-level (NEW) |
|---------|------------------|---------------------|
| Size | 2206 lines | 311 lines (86% smaller) |
| Pattern | Monolithic with inline docs | Executable/docs separation |
| --validate flag | ❌ Missing | ✅ Present |
| --enhance-with-docs | ❌ Missing | ✅ Present |
| SlashCommand tool | ❌ Not allowed | ✅ Allowed |
| Description | Basic | Comprehensive |

### Additional Findings

Discovered 25+ additional user-level commands dated October 2, 2025, suggesting systematic duplication. Recommended follow-up: comprehensive cleanup of `~/.claude/commands/` directory.

### Rollback Procedure (if needed)

```bash
mv ~/.claude/commands/setup.md.backup-20251114 ~/.claude/commands/setup.md
```

### Prevention

- Created comprehensive troubleshooting guide with detection scripts
- Documented command discovery hierarchy
- Recommended against copying project commands to user level
- Suggested periodic duplicate audits

## References

- Screenshot: `/home/benjamin/.config/.claude/specs/setup_choice.md`
- Current command file: `/home/benjamin/.config/.claude/commands/setup.md`
- Implementation plan: `.claude/specs/1763163004_setup_command_duplication/plans/001_fix_duplicate_setup_command.md`
- Troubleshooting guide: `.claude/docs/troubleshooting/duplicate-commands.md`
- Official documentation: https://code.claude.com/docs/en/slash-commands.md

## Metadata

- **Report ID**: 001
- **Topic**: Setup command duplication
- **Created**: 2025-11-14
- **Updated**: 2025-11-14
- **Status**: ✅ RESOLVED - Solution implemented and documented
- **Severity**: Low (usability issue, not functional bug)
