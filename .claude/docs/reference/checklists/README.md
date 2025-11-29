# Checklists Reference

Compliance checklists for command and agent development.

## Purpose

This directory contains actionable checklists that command and agent authors can use to verify their implementations meet project standards before submission.

## Available Checklists

### [Bash Command Compliance](bash-command-compliance.md)

Pre-submission checklist for commands in `.claude/commands/`. Covers:
- Bootstrap requirements (project directory detection)
- Three-tier library sourcing with fail-fast handlers
- Function availability checks
- Automated validation with linter
- Manual testing requirements

**Use When**: Creating new commands or modifying bash blocks in existing commands.

## Checklist Format

All checklists follow this structure:
1. **Pre-Submission Verification**: Items to check before committing
2. **Common Violations**: Table of frequent issues and fixes
3. **Quick Validation Script**: Copy-paste validation commands
4. **Related Documentation**: Links to standards and guides

## Related Documentation

- [Code Standards](../standards/code-standards.md)
- [Output Formatting Standards](../standards/output-formatting.md)
- [Command Development Guide](../../guides/development/command-development/command-development-fundamentals.md)

## Navigation

- [← Parent Directory](../README.md)
- [Related: Standards](../standards/README.md)
- [Related: Guides](../../guides/README.md)
