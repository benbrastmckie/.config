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
- [Neovim Configuration Guidelines](nvim/CLAUDE.md) - Coding standards, style guide, and architecture documentation for Neovim configuration
- [Code Standards](nvim/docs/CODE_STANDARDS.md) - Lua coding conventions, module structure, and development process
- [Documentation Standards](nvim/docs/DOCUMENTATION_STANDARDS.md) - Documentation structure, style guide, and content standards
- [Specifications Directory](nvim/specs/) - Implementation plans, research reports, and technical specifications

### Directory Protocols

#### Specifications Structure (`specs/`)
[Used by: /report, /plan, /implement, /list-plans, /list-reports, /list-summaries]

The specifications directory follows this structure:
- `plans/` - Implementation plans (progressive structure levels)
- `reports/{topic}/` - Research reports organized by topic (format: `NNN_report_name.md`)
- `summaries/` - Implementation summaries linking plans to executed code

All specification documents use incremental three-digit numbering (001, 002, 003...).

**Location**: specs/ directories can exist at project root or in subdirectories for scoped specifications.

**Important**: specs/ directories are gitignored. Never attempt to commit plans, reports, or summaries to git. These are local working artifacts only.

##### Directory Structure Example

```
{project}/
├── specs/
│   ├── reports/
│   │   ├── existing_patterns/
│   │   │   ├── 001_auth_patterns.md
│   │   │   └── 002_session_patterns.md
│   │   ├── security_practices/
│   │   │   └── 001_best_practices.md
│   │   └── alternatives/
│   │       └── 001_implementation_options.md
│   ├── plans/
│   │   ├── 042_user_authentication.md
│   │   └── 043_session_refactor.md
│   └── summaries/
│       ├── 042_implementation_summary.md
│       └── 043_implementation_summary.md
└── debug/
    ├── phase1_failures/
    │   ├── 001_config_initialization.md
    │   └── 002_dependency_missing.md
    └── integration_issues/
        └── 001_auth_timeout.md
```

**Report Organization**:
- Research reports are organized in topic subdirectories under `specs/reports/{topic}/`
- Each topic has its own numbering sequence starting from 001
- Topics are determined during research phase (e.g., "existing_patterns", "security_practices", "alternatives")

**Debug Reports**:
- Debug reports are created in `debug/{topic}/` (separate from specs/)
- Debug reports are NOT gitignored (unlike specs/) for issue tracking
- Topic examples: "phase1_failures", "integration_issues", "config_errors", "test_timeout"
- Created during /orchestrate testing phase failures

##### Plan Structure Levels

Plans use progressive organization that grows based on actual complexity discovered during implementation:

**Level 0: Single File** (All plans start here)
- Format: `NNN_plan_name.md`
- All phases and tasks inline in single file
- Use: All features start here, regardless of anticipated complexity

**Level 1: Phase Expansion** (Created on-demand via `/expand-phase`)
- Format: `NNN_plan_name/` directory with some phases in separate files
- Created when a phase proves too complex during implementation
- Structure:
  - `NNN_plan_name.md` (main plan with summaries)
  - `phase_N_name.md` (expanded phase details)

**Level 2: Stage Expansion** (Created on-demand via `/expand-stage`)
- Format: Phase directories with stage subdirectories
- Created when phases have complex multi-stage workflows
- Structure:
  - `NNN_plan_name/` (plan directory)
    - `phase_N_name/` (phase directory)
      - `phase_N_overview.md`
      - `stage_M_name.md` (stage details)

**Progressive Expansion**: Use `/expand-phase <plan> <phase-num>` to extract complex phases. Use `/expand-stage <phase> <stage-num>` to extract complex stages. Structure grows organically based on implementation needs.

**Collapse Operations**: Use `/collapse-phase` and `/collapse-stage` to merge content back and simplify structure.

## Testing Protocols
[Used by: /test, /test-all, /implement]

### Test Discovery
Commands should check CLAUDE.md in priority order:
1. Project root CLAUDE.md for test commands
2. Subdirectory-specific CLAUDE.md files
3. Language-specific test patterns

### Claude Code Testing
- **Test Location**: `.claude/tests/`
- **Test Runner**: `./run_all_tests.sh`
- **Test Pattern**: `test_*.sh` (Bash test scripts)
- **Coverage Target**: ≥80% for modified code, ≥60% baseline
- **Test Categories**:
  - `test_parsing_utilities.sh` - Plan parsing functions
  - `test_command_integration.sh` - Command workflows
  - `test_progressive_*.sh` - Expansion/collapse operations
  - `test_state_management.sh` - Checkpoint operations
  - `test_shared_utilities.sh` - Utility library functions
  - `test_adaptive_planning.sh` - Adaptive planning integration (16 tests)
  - `test_revise_automode.sh` - /revise auto-mode integration (18 tests)

### Neovim Testing
- **Test Commands**: `:TestNearest`, `:TestFile`, `:TestSuite`, `:TestLast`
- **Test Pattern**: `*_spec.lua`, `test_*.lua` files in `tests/` or adjacent to source
- **Linting**: `<leader>l` to run linter via nvim-lint
- **Formatting**: `<leader>mp` to format code via conform.nvim
- **Custom Tests**: See individual project documentation

### Coverage Requirements
- Aim for >80% coverage on new code
- All public APIs must have tests
- Critical paths require integration tests
- Regression tests for all bug fixes

## Code Standards
[Used by: /implement, /refactor, /plan]

### General Principles
- **Indentation**: 2 spaces, expandtab
- **Line length**: ~100 characters (soft limit)
- **Naming**: snake_case for variables/functions, PascalCase for module tables
- **Error Handling**: Use appropriate error handling for language (pcall for Lua, try-catch for others)
- **Documentation**: Every directory must have a README.md
- **Character Encoding**: UTF-8 only, no emojis in file content

### Language-Specific Standards
- **Lua**: See [Neovim Configuration Guidelines](nvim/CLAUDE.md) for detailed Lua standards
- **Markdown**: Use Unicode box-drawing for diagrams, follow CommonMark spec
- **Shell Scripts**: Follow ShellCheck recommendations, use bash -e for error handling

## Development Philosophy
[Used by: /refactor, /implement, /plan, /document]

### Clean-Break Refactors
- **Prioritize coherence over compatibility**: Clean, well-designed refactors are preferred over maintaining backward compatibility
- **System integration**: What matters is that existing commands and agents work well together in the current implementation
- **No legacy burden**: Don't compromise current design to support old formats or deprecated patterns
- **Migration is acceptable**: Breaking changes are acceptable when they improve system quality

### Documentation Standards
- **Present-focused**: Document the current implementation accurately and clearly
- **No historical reporting**: Don't document changes, updates, or migration paths in main documentation
- **What, not when**: Focus on what the system does now, not how it evolved
- **Clean narrative**: Documentation should read as if the current implementation always existed
- **Ban historical markers**: Never use labels like "(New)", "(Old)", "(Original)", "(Current)", "(Updated)", or version indicators in feature descriptions
- **Timeless writing**: Avoid phrases like "previously", "now supports", "recently added", "in the latest version"

### Rationale
This project values:
1. **Clarity**: Clean, consistent documentation that accurately reflects current state
2. **Quality**: Well-designed systems over backward-compatible compromises
3. **Coherence**: Commands, agents, and utilities that work seamlessly together
4. **Maintainability**: Code that is easy to understand and modify today

When refactoring, prefer to:
- Create clean, consistent interfaces
- Remove deprecated patterns entirely
- Update documentation to reflect only current implementation
- Ensure all components work together harmoniously

Backward compatibility is secondary to these goals.

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
- **Log File**: `.claude/logs/adaptive-planning.log`
- **Log Rotation**: 10MB max, 5 files retained
- **Query Logs**: Use functions from `.claude/lib/adaptive-planning-logger.sh`

### Loop Prevention
- Replan counters tracked in checkpoints
- Max 2 replans per phase enforced
- Replan history logged for audit trail
- User escalation when limit exceeded

### Utilities
- **Checkpoint Management**: `.claude/lib/checkpoint-utils.sh`
- **Complexity Analysis**: `.claude/lib/complexity-utils.sh`
- **Adaptive Logging**: `.claude/lib/adaptive-planning-logger.sh`
- **Error Handling**: `.claude/lib/error-utils.sh`

## Adaptive Planning Configuration
[Used by: /plan, /expand, /implement, /revise]

### Complexity Thresholds

The following thresholds control when plans are automatically expanded or revised during creation and implementation.

- **Expansion Threshold**: 8.0 (phases with complexity score above this threshold are automatically expanded to separate files)
- **Task Count Threshold**: 10 (phases with more tasks than this threshold are expanded regardless of complexity score)
- **File Reference Threshold**: 10 (phases referencing more files than this threshold increase complexity score)
- **Replan Limit**: 2 (maximum number of automatic replans allowed per phase during implementation, prevents infinite loops)

### Adjusting Thresholds

Different projects have different complexity needs. Adjust thresholds to match your project:

**Research-Heavy Project** (detailed documentation preferred):
- Expansion Threshold: 5.0
- Task Count Threshold: 7
- File Reference Threshold: 8

**Simple Web Application** (larger inline phases acceptable):
- Expansion Threshold: 10.0
- Task Count Threshold: 15
- File Reference Threshold: 15

**Mission-Critical System** (maximum organization):
- Expansion Threshold: 3.0
- Task Count Threshold: 5
- File Reference Threshold: 5

### Threshold Ranges

- **Expansion Threshold**: 0.0 - 15.0 (recommended: 3.0 - 12.0)
- **Task Count Threshold**: 5 - 20 (recommended: 5 - 15)
- **File Reference Threshold**: 5 - 30 (recommended: 5 - 20)
- **Replan Limit**: 1 - 5 (recommended: 1 - 3)

## Development Workflow

### Planning and Implementation
1. Create research reports in `specs/reports/` for complex topics
2. Generate implementation plans in `specs/plans/` based on research
3. Execute plans phase-by-phase with testing and commits
4. Generate summaries in `specs/summaries/` linking plans to code
5. Adaptive planning automatically adjusts plans during implementation

### Git Workflow
- Feature branches for new development
- Clean, atomic commits with descriptive messages
- Test before committing
- Document breaking changes

## Project-Specific Commands

### Claude Code Commands
Located in `.claude/commands/`:
- `/implement [plan-file]` - Execute implementation plans
- `/report <topic>` - Generate research documentation
- `/plan <feature>` - Create implementation plans
- `/plan-from-template <template-name>` - Generate plans from reusable templates
- `/test <target>` - Run project-specific tests
- `/setup` - Configure or update this CLAUDE.md file

## Quick Reference

### Common Tasks
- **Run Tests**: `:TestSuite` or `/test-all`
- **Format Code**: `<leader>mp`
- **Check Linting**: `<leader>l`
- **Find Files**: `<C-p>` (Telescope)
- **Search Project**: `<leader>sg` (Telescope grep)

### Navigation
- [Neovim Configuration](nvim/)
- [Specifications](nvim/specs/)
- [Commands](.claude/commands/)

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

## Notes
This CLAUDE.md was automatically configured with the `/setup` command.
For updates or improvements, run `/setup` again or edit manually following the established patterns.

Standards sections are marked with `[Used by: commands]` metadata for discoverability.

