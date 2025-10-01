---
allowed-tools: Read, Write, Edit, MultiEdit, Bash, Grep, Glob
argument-hint: [project-directory]
description: Optimize CLAUDE.md by extracting sections to auxiliary files (integrated into /setup --cleanup)
command-type: primary
dependent-commands: setup, validate-setup
---

# Cleanup CLAUDE.md

**Note**: This command is now integrated into `/setup` as `--cleanup` mode.
For full documentation, see [/setup Cleanup Mode](setup.md#cleanup-mode-workflow).

## Quick Usage

Optimize CLAUDE.md by extracting detailed sections to auxiliary files, keeping the main file concise and easy to navigate:

```bash
/cleanup [project-directory]
```

**Equivalent to**: `/setup --cleanup [project-directory]`

## What It Does

- Analyzes CLAUDE.md for bloat (>30 line sections)
- Identifies extraction candidates (testing details, style guides, diagrams)
- Interactively lets you choose what to extract
- Creates organized auxiliary files in `docs/` directory
- Updates CLAUDE.md with clear links to extracted content
- Preserves all information while improving navigability

## When to Use

Use `/cleanup` or `/setup --cleanup` when:
- CLAUDE.md is >200 lines and hard to navigate
- Detailed reference material buries quick-reference info
- You want to keep CLAUDE.md focused on essentials
- Ongoing maintenance to prevent bloat

## Full Documentation

For complete documentation on extraction logic, workflow, and examples, see:
- [/setup Cleanup Mode](setup.md#cleanup-mode-workflow)
- [Smart Section Extraction](setup.md#2-smart-section-extraction)
- [Interactive Setup](setup.md#interactive-setup)

## Integration with /setup

This standalone command provides the same functionality as `/setup --cleanup` for users who prefer the dedicated command name. Both approaches work identically and use the same underlying extraction logic.
