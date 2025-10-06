# Project Configuration Index

This CLAUDE.md serves as the central configuration and standards index for this project.

## Project Standards and Guidelines

### Core Documentation
- [Neovim Configuration Guidelines](nvim/CLAUDE.md) - Coding standards, style guide, and architecture documentation for Neovim configuration
- [Development Guidelines](nvim/docs/GUIDELINES.md) - Comprehensive development principles, migration strategy, and quality standards
- [Specifications Directory](nvim/specs/) - Implementation plans, research reports, and technical specifications

### Directory Protocols

#### Specifications Structure (`specs/`)
[Used by: /report, /plan, /implement, /list-plans, /list-reports, /list-summaries, /migrate-plan]

The specifications directory follows this structure:
- `plans/` - Implementation plans (adaptive three-tier structure)
- `reports/` - Research reports (format: `NNN_report_name.md`)
- `summaries/` - Implementation summaries linking plans to executed code

All specification documents use incremental three-digit numbering (001, 002, 003...).

**Location**: specs/ directories can exist at project root or in subdirectories for scoped specifications.

##### Plan Structure Tiers

Plans use adaptive organization based on complexity:

**Tier 1: Single File** (Complexity: <50)
- Format: `NNN_plan_name.md`
- Use: Simple features (<10 tasks, <4 phases)

**Tier 2: Phase Directory** (Complexity: 50-200)
- Format: `NNN_plan_name/` directory with overview + phase files
- Use: Medium features (10-50 tasks, 4-10 phases)
- Structure:
  - `NNN_plan_name.md` (overview)
  - `phase_1_name.md` (phase details)
  - `phase_2_name.md` (phase details)

**Tier 3: Hierarchical Tree** (Complexity: ≥200)
- Format: `NNN_plan_name/` with nested phase directories
- Use: Complex features (>50 tasks, >10 phases)
- Structure:
  - `NNN_plan_name.md` (overview)
  - `phase_1_name/` (phase directory)
    - `phase_1_overview.md`
    - `stage_1_name.md`
    - `stage_2_name.md`

**Tier Selection**: Automatic based on complexity score. Use `/migrate-plan` to convert between tiers.

**Complexity Formula**: `score = (tasks × 1.0) + (phases × 5.0) + (hours × 0.5) + (dependencies × 2.0)`

See [Adaptive Plan Structures Guide](.claude/docs/adaptive-plan-structures.md) for complete documentation.

## Testing Protocols
[Used by: /test, /test-all, /implement]

### Test Discovery
Commands should check CLAUDE.md in priority order:
1. Project root CLAUDE.md for test commands
2. Subdirectory-specific CLAUDE.md files
3. Language-specific test patterns

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

## Development Workflow

### Planning and Implementation
1. Create research reports in `specs/reports/` for complex topics
2. Generate implementation plans in `specs/plans/` based on research
3. Execute plans phase-by-phase with testing and commits
4. Generate summaries in `specs/summaries/` linking plans to code

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

### Documentation Updates
- Update documentation with code changes
- Keep examples current with implementation
- Document breaking changes prominently

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

