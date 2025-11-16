# Worktree Task: optimize_claude

## Task Metadata
- **Type**: feature
- **Branch**: feature/optimize_claude
- **Created**: 2025-10-09 16:45
- **Worktree**: ../.config-feature-optimize_claude
- **Session ID**: optimize_claude-1760053547

## Objective
[Describe the main goal for this worktree]

## Current Status
- [ ] Planning
- [ ] Implementation
- [ ] Testing
- [ ] Documentation
- [ ] Review

## Claude Context
Tell Claude: "I'm working on optimize_claude in the feature/optimize_claude worktree. The goal is to..."

## Task Notes
[Add worktree-specific context, links, or decisions]


---

# Project Configuration (Inherited from Main Worktree)

# Project Configuration Index

This CLAUDE.md serves as the central configuration and standards index for this project.

## Project Standards and Guidelines

### Core Documentation
- [Claude Code Documentation](.claude/docs/README.md) - Complete index of patterns, guides, workflows, and reference documentation for working with .claude/ system
- [Neovim Configuration Guidelines](nvim/CLAUDE.md) - Coding standards, style guide, and architecture documentation for Neovim configuration
- [Code Standards](nvim/docs/CODE_STANDARDS.md) - Lua coding conventions, module structure, and development process
- [Documentation Standards](nvim/docs/DOCUMENTATION_STANDARDS.md) - Documentation structure, style guide, and content standards
- [Specifications Directory](nvim/specs/) - Implementation plans, research reports, and technical specifications

<!-- SECTION: directory_protocols -->
### Directory Protocols

[Used by: /research, /plan, /implement, /list-plans, /list-reports, /list-summaries]

The specifications directory uses a topic-based structure (`specs/{NNN_topic}/`) with artifact subdirectories (plans/, reports/, summaries/, debug/). Plans use progressive organization (Level 0 → Level 1 → Level 2) and support phase dependencies for wave-based parallel execution.

Key concepts:
- **Topic-based structure**: All artifacts for a feature in one numbered directory
- **Plan levels**: Single file → Phase expansion → Stage expansion (on-demand)
- **Phase dependencies**: Enable parallel execution of independent phases (40-60% time savings)
- **Artifact lifecycle**: Debug reports committed, others gitignored

See [Directory Protocols](.claude/docs/concepts/directory-protocols.md) for complete structure, examples, and dependency syntax.
<!-- END_SECTION: directory_protocols -->

<!-- SECTION: testing_protocols -->
## Testing Protocols
[Used by: /test, /test-all, /implement]

See [Testing Protocols](.claude/docs/reference/testing-protocols.md) for complete test discovery, patterns, coverage requirements, and isolation standards.
<!-- END_SECTION: testing_protocols -->

<!-- SECTION: code_standards -->
## Code Standards
[Used by: /implement, /refactor, /plan]

See [Code Standards](.claude/docs/reference/code-standards.md) for complete coding conventions, language-specific standards, architectural requirements, and link conventions.
<!-- END_SECTION: code_standards -->

<!-- SECTION: directory_organization -->
## Directory Organization Standards
[Used by: /implement, /plan, /refactor, all development commands]

See [Directory Organization](.claude/docs/concepts/directory-organization.md) for complete directory structure, file placement rules, decision matrix, and anti-patterns.

**Quick Summary**: `.claude/` contains scripts/ (standalone tools), lib/ (sourced functions), commands/ (slash commands), agents/ (AI assistants), docs/ (documentation), and tests/ (test suites).
<!-- END_SECTION: directory_organization -->

<!-- SECTION: development_philosophy -->
## Development Philosophy
[Used by: /refactor, /implement, /plan, /document]

See [Writing Standards](.claude/docs/concepts/writing-standards.md) for complete development philosophy, clean-break approach, and documentation standards.
<!-- END_SECTION: development_philosophy -->

<!-- SECTION: adaptive_planning -->
## Adaptive Planning
[Used by: /implement]

See [Adaptive Planning Guide](.claude/docs/workflows/adaptive-planning-guide.md) for intelligent plan revision capabilities, automatic triggers, and loop prevention.
<!-- END_SECTION: adaptive_planning -->

<!-- SECTION: adaptive_planning_config -->
## Adaptive Planning Configuration
[Used by: /plan, /expand, /implement, /revise]

See [Adaptive Planning Configuration](.claude/docs/reference/adaptive-planning-config.md) for complexity thresholds, threshold adjustment guidelines, and configuration ranges.
<!-- END_SECTION: adaptive_planning_config -->

<!-- SECTION: development_workflow -->
## Development Workflow
[Used by: /implement, /plan, /coordinate]

See [Development Workflow](.claude/docs/concepts/development-workflow.md) for complete workflow documentation with spec updater details.
<!-- END_SECTION: development_workflow -->

<!-- SECTION: hierarchical_agent_architecture -->
## Hierarchical Agent Architecture
[Used by: /coordinate, /implement, /plan, /debug]

See [Hierarchical Agent Architecture Guide](.claude/docs/concepts/hierarchical_agents.md) for complete patterns, utilities, templates, and troubleshooting.
<!-- END_SECTION: hierarchical_agent_architecture -->

<!-- SECTION: state_based_orchestration -->
## State-Based Orchestration Architecture
[Used by: /coordinate, custom orchestrators]

See [State-Based Orchestration Overview](.claude/docs/architecture/state-based-orchestration-overview.md) for complete architecture, migration guide, and performance metrics.
<!-- END_SECTION: state_based_orchestration -->

<!-- SECTION: configuration_portability -->
## Configuration Portability and Command Discovery
[Used by: all commands, project setup, troubleshooting]

See [Duplicate Commands Troubleshooting](.claude/docs/troubleshooting/duplicate-commands.md) for command/agent/hook discovery hierarchy and configuration portability.
<!-- END_SECTION: configuration_portability -->

<!-- SECTION: project_commands -->
## Project-Specific Commands
[Used by: all commands, /help]

See [Command Reference](.claude/docs/reference/command-reference.md) for complete catalog of slash commands with syntax and examples.
<!-- END_SECTION: project_commands -->

<!-- SECTION: quick_reference -->
## Quick Reference
[Used by: all commands]

See [Quick Reference](.claude/docs/quick-reference/README.md) for common tasks, setup utilities, command/agent references, and navigation links.
<!-- END_SECTION: quick_reference -->

<!-- SECTION: documentation_policy -->
## Documentation Policy
[Used by: /document, /plan]

### README Requirements
Every subdirectory must have a README.md containing:
- **Purpose**: Clear explanation of directory role
- **Module Documentation**: Documentation for each file/module
- **Usage Examples**: Code examples where applicable
- **Navigation Links**: Links to parent and subdirectory READMEs

### Documentation Format
- Use clear, concise language
- Include code examples with syntax highlighting
- Use Unicode box-drawing for diagrams (see nvim/CLAUDE.md)
- No emojis in file content (UTF-8 encoding issues)
- Follow CommonMark specification
- No historical commentary (see Development Philosophy → Documentation Standards)

### Documentation Updates
- Update documentation with code changes
- Keep examples current with implementation
- Document breaking changes prominently
- Remove any historical markers when updating existing docs
<!-- END_SECTION: documentation_policy -->

<!-- SECTION: standards_discovery -->
## Standards Discovery
[Used by: all commands]

### Discovery Method
Commands should discover standards by:
1. Searching upward from current directory for CLAUDE.md
2. Checking for subdirectory-specific CLAUDE.md files
3. Merging/overriding: subdirectory standards extend parent standards

### Subdirectory Standards
- Subdirectory CLAUDE.md files can override parent standards
- Always check most specific (deepest) CLAUDE.md first
- Fall back to parent standards for missing sections

### Fallback Behavior
When CLAUDE.md not found or incomplete:
- Use sensible language-specific defaults
- Suggest creating/updating CLAUDE.md with `/setup`
- Continue with graceful degradation
<!-- END_SECTION: standards_discovery -->

## Notes
This CLAUDE.md was automatically configured with the `/setup` command.
For updates or improvements, run `/setup` again or edit manually following the established patterns.

Standards sections are marked with `[Used by: commands]` metadata for discoverability.


