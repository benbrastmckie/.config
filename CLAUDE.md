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

This project prioritizes clean, coherent systems over backward compatibility. Refactors should create well-designed interfaces without legacy burden. Documentation should be present-focused and timeless, avoiding historical markers like "(New)" or "previously".

Core values: clarity, quality, coherence, maintainability.

### Architectural Principles

- **Clean separation between executable logic and documentation**: Commands and agents use two-file pattern (lean executable + comprehensive guide) enabling fail-fast execution and independent documentation growth without context bloat
- **Single source of truth**: Each piece of information exists in exactly one authoritative location
- **Progressive disclosure**: Information revealed when needed, not all upfront
- **Context window optimization**: Minimize context consumption through metadata extraction and aggressive pruning

### Clean-Break and Fail-Fast Approach

This configuration maintains a **clean-break, fail-fast evolution philosophy**:

**Clean Break**:
- Delete obsolete code immediately after migration
- No deprecation warnings, compatibility shims, or transition periods
- No archives beyond git history
- Configuration and code describe what they are, not what they were

**Fail Fast**:
- Missing files produce immediate, obvious bash errors
- Tests pass or fail immediately (no monitoring periods)
- Breaking changes break loudly with clear error messages
- No silent fallbacks or graceful degradation

**Critical Distinction - Fallback Types** (Spec 057):
- **Bootstrap fallbacks**: PROHIBITED (hide configuration errors through silent function definitions)
- **Verification fallbacks**: REQUIRED (detect tool/agent failures immediately, terminate with diagnostics)
- **Optimization fallbacks**: ACCEPTABLE (performance caches only, graceful degradation for non-critical features)

Standard 0 (Execution Enforcement) uses verification checkpoints to detect errors immediately, not hide them. Orchestrators verify file creation and fail-fast when agents don't create expected artifacts. See [Fail-Fast Policy Analysis](.claude/specs/634_001_coordinate_improvementsmd_implements/reports/001_fail_fast_policy_analysis.md) for complete taxonomy.

**Avoid Cruft**:
- No historical commentary in active files
- No backward compatibility layers
- No migration tracking spreadsheets (use git commits)
- No "what changed" documentation (use git log)

**Rationale**: Configuration should focus on being what it is without extra commentary on top. Clear, immediate failures are better than hidden complexity masking problems.

See [Writing Standards](.claude/docs/concepts/writing-standards.md) for complete refactoring principles and documentation standards.
<!-- END_SECTION: development_philosophy -->

<!-- SECTION: adaptive_planning -->
## Adaptive Planning
[Used by: /implement]

### Overview
`/implement` includes intelligent plan revision capabilities that automatically detect when replanning is needed during execution.

### Automatic Triggers
1. **Complexity Detection**: Phase complexity score >8 or >10 tasks triggers phase expansion
2. **Test Failure Patterns**: 2+ consecutive test failures in same phase suggests missing prerequisites
3. **Scope Drift**: Manual flag `--report-scope-drift "description"` for discovered out-of-scope work

### Behavior
- Automatically invokes `/revise --auto-mode` when triggers detected
- Updates plan structure (expands phases, adds phases, or updates tasks)
- Continues implementation with revised plan
- Maximum 2 replans per phase prevents infinite loops

### Logging
- **Log File**: `.claude/data/logs/adaptive-planning.log`
- **Log Rotation**: 10MB max, 5 files retained
- **Query Logs**: Use functions from `.claude/lib/unified-logger.sh`

### Loop Prevention
- Replan counters tracked in checkpoints
- Max 2 replans per phase enforced
- Replan history logged for audit trail
- User escalation when limit exceeded

### Utilities
- **Checkpoint Management**: `.claude/lib/checkpoint-utils.sh` - See [Checkpoint Recovery Pattern](.claude/docs/concepts/patterns/checkpoint-recovery.md)
- **Complexity Analysis**: `.claude/lib/complexity-utils.sh`
- **Adaptive Logging**: `.claude/lib/unified-logger.sh`
- **Error Handling**: `.claude/lib/error-handling.sh`
- **Context Management**: See [Context Management Pattern](.claude/docs/concepts/patterns/context-management.md) for pruning and reduction techniques
<!-- END_SECTION: adaptive_planning -->

<!-- SECTION: adaptive_planning_config -->
## Adaptive Planning Configuration
[Used by: /plan, /expand, /implement, /revise]

See [Adaptive Planning Configuration](.claude/docs/reference/adaptive-planning-config.md) for complexity thresholds, threshold adjustment guidelines, and configuration ranges.
<!-- END_SECTION: adaptive_planning_config -->

<!-- SECTION: development_workflow -->
## Development Workflow
[Used by: /implement, /plan, /orchestrate, /coordinate]

Standard workflow: research → plan → implement → test → commit → summarize. The spec updater agent manages artifacts in topic-based directories and maintains cross-references. Adaptive planning adjusts plans during implementation.

Key patterns:
- **5-phase workflow**: Reports, plans, execution, summaries, adaptive adjustments
- **Spec updater integration**: Artifact management, lifecycle tracking, gitignore compliance
- **Plan hierarchy updates**: Automatic checkbox propagation across plan levels
- **Git workflow**: Feature branches, atomic commits, test before commit
- **Checkpoint Recovery**: State preservation for resumable workflows - See [Checkpoint Recovery Pattern](.claude/docs/concepts/patterns/checkpoint-recovery.md)
- **Parallel Execution**: Wave-based implementation for 40-60% time savings - See [Parallel Execution Pattern](.claude/docs/concepts/patterns/parallel-execution.md)

See [Development Workflow](.claude/docs/concepts/development-workflow.md) for spec updater details, artifact lifecycle, and integration patterns.
<!-- END_SECTION: development_workflow -->

<!-- SECTION: hierarchical_agent_architecture -->
## Hierarchical Agent Architecture
[Used by: /orchestrate, /implement, /plan, /debug]

Multi-level agent coordination with metadata-based context passing achieves 95.6% context reduction and 60-80% time savings through parallel execution. Key capabilities: recursive supervision (10+ agents), imperative invocation pattern (Standard 11), LLM-based workflow classification, and aggressive context pruning.

**Core Libraries**: metadata-extraction.sh, plan-core-bundle.sh, context-pruning.sh, workflow-llm-classifier.sh

See [Hierarchical Agent Architecture Guide](.claude/docs/concepts/hierarchical_agents.md) for complete patterns, utilities, agent templates, command integration, and troubleshooting.
<!-- END_SECTION: hierarchical_agent_architecture -->

<!-- SECTION: state_based_orchestration -->
## State-Based Orchestration Architecture
[Used by: /coordinate, /orchestrate, /supervise, custom orchestrators]

State-based orchestration uses explicit state machines with validated transitions for multi-phase workflows. Achieves 48.9% code reduction and 67% performance improvement through selective persistence, atomic transitions, and hierarchical supervisor coordination.

**Core Libraries**: workflow-state-machine.sh, state-persistence.sh, checkpoint-utils.sh (Schema V2.0)

See [State-Based Orchestration Overview](.claude/docs/architecture/state-based-orchestration-overview.md) for complete architecture, [State Machine Development Guide](.claude/docs/guides/state-machine-orchestrator-development.md) for creating orchestrators, and [Migration Guide](.claude/docs/guides/state-machine-migration-guide.md) for phase-to-state transitions.
<!-- END_SECTION: state_based_orchestration -->

<!-- SECTION: project_commands -->
## Project-Specific Commands
[Used by: all commands, /help]

All commands located in `.claude/commands/`. Primary orchestration: `/coordinate` (production-ready, 2,371 lines). Core workflow commands: `/research`, `/plan`, `/implement`, `/test`, `/debug`, `/document`. Planning utilities: `/plan-wizard`, `/plan-from-template`. Setup: `/setup [--enhance-with-docs]`.

**Command Architecture**: Executable/documentation separation pattern - lean executables (<250 lines) + comprehensive guides. See [Standard 14](.claude/docs/reference/command_architecture_standards.md#standard-14).

**Performance**: >90% agent delegation, 100% file creation reliability, 40-60% time savings (wave-based execution), <30% context usage.

See [Command Reference](.claude/docs/reference/command-reference.md) for complete catalog with syntax and examples. See [Orchestration Best Practices](.claude/docs/guides/orchestration-best-practices.md) for command selection guide and unified framework.
<!-- END_SECTION: project_commands -->

<!-- SECTION: quick_reference -->
## Quick Reference
[Used by: all commands]

### Common Tasks
- **Run Tests**: `:TestSuite` or `/test-all`
- **Format Code**: `<leader>mp`
- **Check Linting**: `<leader>l`
- **Find Files**: `<C-p>` (Telescope)
- **Search Project**: `<leader>sg` (Telescope grep)

### Setup Utilities
- **Test Detection**: `.claude/lib/detect-testing.sh [dir]` - Score testing infrastructure (0-6)
- **Optimize CLAUDE.md**: `.claude/lib/optimize-claude-md.sh CLAUDE.md --dry-run` - Analyze bloat
- **Generate READMEs**: `.claude/lib/generate-readme.sh --generate-all [dir]` - Documentation coverage

See [Setup Guide](.claude/docs/guides/setup-command-guide.md) for detailed usage patterns and troubleshooting.

### Command and Agent Reference
- [Command Reference](.claude/docs/reference/command-reference.md) - Complete catalog of all slash commands with syntax and examples
- [Agent Reference](.claude/docs/reference/agent-reference.md) - Complete catalog of all specialized agents with capabilities and usage

### Command Development
- **New Command**: Start with [_template-executable-command.md](.claude/docs/guides/_template-executable-command.md)
- **Command Guide**: Use [_template-command-guide.md](.claude/docs/guides/_template-command-guide.md)
- **Pattern Guide**: [Command Development Guide - Section 2.4](.claude/docs/guides/command-development-guide.md#24-executabledocumentation-separation-pattern) for complete separation pattern details
- **Validation**: Run `.claude/tests/validate_executable_doc_separation.sh` to verify pattern compliance

### Navigation
- [Neovim Configuration](nvim/)
- [Specifications](nvim/specs/)
- [Commands](.claude/commands/)
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


